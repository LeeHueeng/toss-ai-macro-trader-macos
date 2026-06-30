#!/usr/bin/env node

import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const outputDir = path.join(repoRoot, "docs", "tossinvest");
const sourceDir = path.join(outputDir, "source");

const sources = {
  llms: "https://developers.tossinvest.com/llms.txt",
  overview: "https://openapi.tossinvest.com/openapi-docs/overview.md",
  apiReference:
    "https://openapi.tossinvest.com/openapi-docs/latest/api-reference/README.md",
  openapi: "https://openapi.tossinvest.com/openapi-docs/latest/openapi.json",
};

const methodOrder = ["get", "post", "put", "patch", "delete", "options", "head"];

function stableStringify(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

async function fetchResource(url, expectedType) {
  const response = await fetch(url, {
    headers: {
      accept:
        expectedType === "json"
          ? "application/json, text/plain;q=0.9, */*;q=0.8"
          : "text/markdown, text/plain, */*;q=0.8",
      "user-agent": "toss-chart-docs-sync/1.0",
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.status} ${response.statusText}`);
  }

  return expectedType === "json" ? response.json() : response.text();
}

function refName(ref) {
  return ref ? decodeURIComponent(ref.split("/").pop()) : undefined;
}

function resolveLocalRef(document, ref) {
  if (!ref?.startsWith("#/")) {
    return undefined;
  }

  return ref
    .slice(2)
    .split("/")
    .map((part) => part.replaceAll("~1", "/").replaceAll("~0", "~"))
    .reduce((current, part) => current?.[part], document);
}

function schemaLabel(schema) {
  if (!schema) {
    return undefined;
  }
  if (schema.$ref) {
    return refName(schema.$ref);
  }
  if (schema.allOf) {
    return `allOf<${schema.allOf.map(schemaLabel).filter(Boolean).join(", ")}>`;
  }
  if (schema.oneOf) {
    return `oneOf<${schema.oneOf.map(schemaLabel).filter(Boolean).join(", ")}>`;
  }
  if (schema.anyOf) {
    return `anyOf<${schema.anyOf.map(schemaLabel).filter(Boolean).join(", ")}>`;
  }
  if (schema.type === "array") {
    return `array<${schemaLabel(schema.items) ?? "unknown"}>`;
  }
  if (schema.enum) {
    return `enum<${schema.enum.join(" | ")}>`;
  }
  if (schema.type) {
    return schema.format ? `${schema.type}:${schema.format}` : schema.type;
  }
  return undefined;
}

function compactSchema(schema) {
  if (!schema) {
    return undefined;
  }

  if (schema.$ref) {
    return { ref: refName(schema.$ref) };
  }

  const compact = {};
  for (const key of ["type", "format", "nullable", "deprecated", "minimum", "maximum"]) {
    if (schema[key] !== undefined) {
      compact[key] = schema[key];
    }
  }
  if (schema.enum) {
    compact.enum = schema.enum;
  }
  if (schema.default !== undefined) {
    compact.default = schema.default;
  }
  if (schema.example !== undefined) {
    compact.example = schema.example;
  }
  if (schema.items) {
    compact.items = compactSchema(schema.items);
  }
  for (const key of ["allOf", "oneOf", "anyOf"]) {
    if (schema[key]) {
      compact[key] = schema[key].map(compactSchema);
    }
  }
  if (schema.properties) {
    compact.properties = Object.fromEntries(
      Object.entries(schema.properties).map(([name, property]) => [
        name,
        compactSchema(property),
      ]),
    );
  }
  if (schema.required) {
    compact.required = schema.required;
  }

  return Object.keys(compact).length > 0 ? compact : undefined;
}

function extractParameter(openapi, parameter) {
  const resolved = parameter.$ref ? resolveLocalRef(openapi, parameter.$ref) : parameter;
  if (!resolved) {
    return { ref: refName(parameter.$ref) };
  }

  return {
    ref: parameter.$ref ? refName(parameter.$ref) : undefined,
    name: resolved.name,
    in: resolved.in,
    required: Boolean(resolved.required),
    schema: schemaLabel(resolved.schema),
    schemaDetail: compactSchema(resolved.schema),
    description: resolved.description,
  };
}

function flattenParameters(openapi, pathItem, operation) {
  return [...(pathItem.parameters ?? []), ...(operation.parameters ?? [])].map(
    (parameter) => extractParameter(openapi, parameter),
  );
}

function extractRequestBody(openapi, requestBody) {
  if (!requestBody) {
    return undefined;
  }
  const ref = requestBody.$ref ? refName(requestBody.$ref) : undefined;
  const resolved = requestBody.$ref ? resolveLocalRef(openapi, requestBody.$ref) : requestBody;
  if (!resolved) {
    return { ref };
  }

  const content = Object.fromEntries(
    Object.entries(resolved.content ?? {}).map(([contentType, media]) => [
      contentType,
      {
        schema: schemaLabel(media.schema),
        schemaDetail: compactSchema(media.schema),
        example: media.example,
        examples: media.examples
          ? Object.fromEntries(
              Object.entries(media.examples).map(([name, example]) => [
                name,
                example.value ?? { ref: refName(example.$ref) },
              ]),
            )
          : undefined,
      },
    ]),
  );

  return {
    ref,
    required: Boolean(resolved.required),
    description: resolved.description,
    content,
  };
}

function extractResponse(openapi, response) {
  const ref = response.$ref ? refName(response.$ref) : undefined;
  const resolved = response.$ref ? resolveLocalRef(openapi, response.$ref) : response;
  if (!resolved) {
    return { ref };
  }

  const content = Object.fromEntries(
    Object.entries(resolved.content ?? {}).map(([contentType, media]) => [
      contentType,
      {
        schema: schemaLabel(media.schema),
        schemaDetail: compactSchema(media.schema),
        example: media.example,
        examples: media.examples ? Object.keys(media.examples) : undefined,
      },
    ]),
  );

  return {
    ref,
    description: resolved.description,
    content,
  };
}

function extractResponses(openapi, responses) {
  return Object.fromEntries(
    Object.entries(responses ?? {}).map(([status, response]) => [
      status,
      extractResponse(openapi, response),
    ]),
  );
}

function extractSecurity(openapi, operation) {
  const security = operation.security ?? openapi.security ?? [];
  return security.flatMap((requirement) =>
    Object.entries(requirement).map(([scheme, scopes]) => ({
      scheme,
      scopes,
    })),
  );
}

function extractEndpoints(openapi) {
  return Object.entries(openapi.paths ?? {}).flatMap(([route, pathItem]) =>
    methodOrder
      .filter((method) => pathItem[method])
      .map((method) => {
        const operation = pathItem[method];
        return {
          method: method.toUpperCase(),
          path: route,
          operationId: operation.operationId,
          tags: operation.tags ?? [],
          summary: operation.summary,
          deprecated: Boolean(operation.deprecated),
          security: extractSecurity(openapi, operation),
          parameters: flattenParameters(openapi, pathItem, operation),
          requestBody: extractRequestBody(openapi, operation.requestBody),
          responses: extractResponses(openapi, operation.responses),
        };
      }),
  );
}

function extractSchemas(openapi) {
  return Object.fromEntries(
    Object.entries(openapi.components?.schemas ?? {}).map(([name, schema]) => {
      const required = new Set(schema.required ?? []);
      const properties = schema.properties
        ? Object.fromEntries(
            Object.entries(schema.properties).map(([propertyName, property]) => [
              propertyName,
              {
                required: required.has(propertyName),
                schema: schemaLabel(property),
                schemaDetail: compactSchema(property),
                description: property.description,
              },
            ]),
          )
        : undefined;

      return [
        name,
        {
          type: schemaLabel(schema),
          description: schema.description,
          required: schema.required ?? [],
          properties,
          enum: schema.enum,
          schemaDetail: compactSchema(schema),
        },
      ];
    }),
  );
}

function groupEndpoints(endpoints) {
  const groups = {};
  for (const endpoint of endpoints) {
    const tags = endpoint.tags.length > 0 ? endpoint.tags : ["untagged"];
    for (const tag of tags) {
      groups[tag] ??= [];
      groups[tag].push({
        method: endpoint.method,
        path: endpoint.path,
        operationId: endpoint.operationId,
        summary: endpoint.summary,
      });
    }
  }
  return groups;
}

function toMarkdownTable(rows) {
  if (rows.length === 0) {
    return "";
  }
  const headers = Object.keys(rows[0]);
  const escapeCell = (value) =>
    String(value ?? "")
      .replaceAll("\n", " ")
      .replaceAll("|", "\\|");

  return [
    `| ${headers.join(" | ")} |`,
    `| ${headers.map(() => "---").join(" | ")} |`,
    ...rows.map((row) => `| ${headers.map((header) => escapeCell(row[header])).join(" | ")} |`),
  ].join("\n");
}

function endpointAuthLabel(endpoint) {
  if (!endpoint.security || endpoint.security.length === 0) {
    return "none";
  }
  return endpoint.security.map((item) => item.scheme).join(", ");
}

function responseSummary(endpoint) {
  return Object.entries(endpoint.responses)
    .map(([status, response]) => {
      const contentTypes = Object.keys(response.content ?? {});
      const schemas = contentTypes
        .map((contentType) => response.content?.[contentType]?.schema)
        .filter(Boolean);
      return `${status}${schemas.length ? ` (${schemas.join(", ")})` : ""}`;
    })
    .join(", ");
}

function generateMarkdown(openapi, structure, generatedAt) {
  const endpointRows = structure.endpoints.map((endpoint) => ({
    Method: endpoint.method,
    Path: endpoint.path,
    Tag: endpoint.tags.join(", "),
    Operation: endpoint.operationId ?? "",
    Auth: endpointAuthLabel(endpoint),
    Summary: endpoint.summary ?? "",
  }));

  const sections = [
    `# ${openapi.info?.title ?? "Toss Invest Open API"} Structure`,
    "",
    `Generated at: ${generatedAt}`,
    "",
    "## Sources",
    "",
    toMarkdownTable(
      Object.entries(sources).map(([name, url]) => ({
        Name: name,
        URL: url,
      })),
    ),
    "",
    "## API Metadata",
    "",
    toMarkdownTable([
      {
        Title: openapi.info?.title ?? "",
        Version: openapi.info?.version ?? "",
        OpenAPI: openapi.openapi ?? "",
        Servers: (openapi.servers ?? []).map((server) => server.url).join(", "),
      },
    ]),
    "",
    "## Security Schemes",
    "",
    toMarkdownTable(
      Object.entries(openapi.components?.securitySchemes ?? {}).map(([name, scheme]) => ({
        Name: name,
        Type: scheme.type ?? "",
        Scheme: scheme.scheme ?? "",
        BearerFormat: scheme.bearerFormat ?? "",
        TokenUrl: scheme.flows?.clientCredentials?.tokenUrl ?? "",
      })),
    ),
    "",
    "## Endpoint Index",
    "",
    toMarkdownTable(endpointRows),
    "",
    "## Endpoints By Tag",
    "",
  ];

  for (const [tag, endpoints] of Object.entries(structure.endpointsByTag)) {
    sections.push(`### ${tag}`, "");
    sections.push(
      toMarkdownTable(
        endpoints.map((endpoint) => ({
          Method: endpoint.method,
          Path: endpoint.path,
          Operation: endpoint.operationId ?? "",
          Summary: endpoint.summary ?? "",
        })),
      ),
      "",
    );
  }

  sections.push("## Endpoint Details", "");
  for (const endpoint of structure.endpoints) {
    sections.push(
      `### ${endpoint.method} ${endpoint.path}`,
      "",
      toMarkdownTable([
        {
          Operation: endpoint.operationId ?? "",
          Tags: endpoint.tags.join(", "),
          Auth: endpointAuthLabel(endpoint),
          Deprecated: endpoint.deprecated ? "yes" : "no",
          Responses: responseSummary(endpoint),
        },
      ]),
      "",
    );

    if (endpoint.parameters.length > 0) {
      sections.push(
        "Parameters:",
        "",
        toMarkdownTable(
          endpoint.parameters.map((parameter) => ({
            Name: parameter.name ?? parameter.ref ?? "",
            In: parameter.in ?? "",
            Required: parameter.required ? "yes" : "no",
            Schema: parameter.schema ?? parameter.ref ?? "",
            Description: parameter.description ?? "",
          })),
        ),
        "",
      );
    }

    if (endpoint.requestBody) {
      sections.push(
        "Request body:",
        "",
        toMarkdownTable(
          Object.entries(endpoint.requestBody.content ?? {}).map(([contentType, media]) => ({
            ContentType: contentType,
            Required: endpoint.requestBody.required ? "yes" : "no",
            Schema: media.schema ?? "",
          })),
        ),
        "",
      );
    }
  }

  sections.push("## Schemas", "");
  for (const [schemaName, schema] of Object.entries(structure.schemas)) {
    sections.push(`### ${schemaName}`, "");
    if (schema.description) {
      sections.push(schema.description.replaceAll("\n", " "), "");
    }
    if (schema.properties) {
      sections.push(
        toMarkdownTable(
          Object.entries(schema.properties).map(([propertyName, property]) => ({
            Property: propertyName,
            Required: property.required ? "yes" : "no",
            Schema: property.schema ?? "",
            Description: property.description ?? "",
          })),
        ),
        "",
      );
    } else if (schema.enum) {
      sections.push(`Enum: ${schema.enum.join(", ")}`, "");
    }
  }

  return `${sections.join("\n")}\n`;
}

async function main() {
  const generatedAt = new Date().toISOString();
  await mkdir(sourceDir, { recursive: true });

  const [llms, overview, apiReference, openapi] = await Promise.all([
    fetchResource(sources.llms, "text"),
    fetchResource(sources.overview, "text"),
    fetchResource(sources.apiReference, "text"),
    fetchResource(sources.openapi, "json"),
  ]);

  const endpoints = extractEndpoints(openapi);
  const structure = {
    generatedAt,
    sources,
    info: {
      title: openapi.info?.title,
      version: openapi.info?.version,
      openapi: openapi.openapi,
    },
    servers: openapi.servers ?? [],
    tags: openapi.tags ?? [],
    securitySchemes: openapi.components?.securitySchemes ?? {},
    globalSecurity: openapi.security ?? [],
    endpointCount: endpoints.length,
    schemaCount: Object.keys(openapi.components?.schemas ?? {}).length,
    endpoints,
    endpointsByTag: groupEndpoints(endpoints),
    schemas: extractSchemas(openapi),
  };

  const readme = [
    "# Toss Invest API Docs Cache",
    "",
    "This folder is generated from the official Toss Invest Open API sources.",
    "",
    "Run:",
    "",
    "```sh",
    "node scripts/fetch-tossinvest-docs.mjs",
    "```",
    "",
    "Generated files:",
    "",
    "- `source/llms.txt`: official LLM discovery file.",
    "- `source/overview.md`: official overview markdown.",
    "- `source/api-reference.md`: official API reference markdown.",
    "- `openapi.json`: canonical OpenAPI document.",
    "- `api-structure.json`: normalized endpoint/schema index.",
    "- `API_STRUCTURE.md`: human-readable endpoint/schema index.",
    "",
    `Last generated: ${generatedAt}`,
    "",
  ].join("\n");

  await Promise.all([
    writeFile(path.join(sourceDir, "llms.txt"), llms),
    writeFile(path.join(sourceDir, "overview.md"), overview),
    writeFile(path.join(sourceDir, "api-reference.md"), apiReference),
    writeFile(path.join(outputDir, "openapi.json"), stableStringify(openapi)),
    writeFile(path.join(outputDir, "api-structure.json"), stableStringify(structure)),
    writeFile(path.join(outputDir, "API_STRUCTURE.md"), generateMarkdown(openapi, structure, generatedAt)),
    writeFile(path.join(outputDir, "README.md"), readme),
  ]);

  console.log(
    `Saved ${endpoints.length} endpoints and ${structure.schemaCount} schemas to ${path.relative(
      repoRoot,
      outputDir,
    )}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
