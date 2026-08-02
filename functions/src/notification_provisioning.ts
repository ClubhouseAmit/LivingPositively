const LOCALES = ["he", "ar", "en"] as const;
const QUOTE_KEY_PATTERN = /^inspirationalQuotesNo(\d+)$/;
const FIREBASE_PROJECT_ID_PATTERN = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;

type Locale = (typeof LOCALES)[number];
type GenderVariants = {
  male: string;
  female: string;
  other: string;
};

export type SeedDocument = {
  collection: string;
  id: string;
  data: Record<string, unknown>;
};

export type SeedWriter = {
  setDocument(document: SeedDocument): Promise<void>;
};

export function parseProvisionProjectId(args: string[]): string {
  if (args.length !== 2 || args[0] !== "--project") {
    throw new Error(
      "Usage: npm run provision:notifications -- --project <firebase-project-id>",
    );
  }
  const projectId = args[1];
  if (!FIREBASE_PROJECT_ID_PATTERN.test(projectId)) {
    throw new Error(`Invalid Firebase project ID: ${projectId}`);
  }
  return projectId;
}

function findJsonStringEnd(source: string, start: number): number {
  let position = start + 1;
  while (position < source.length) {
    if (source[position] === "\\") {
      position += 2;
    } else if (source[position] === "\"") {
      return position + 1;
    } else {
      position++;
    }
  }
  throw new Error("Unterminated JSON string");
}

function findJsonValueEnd(source: string, start: number): number {
  if (source[start] === "\"") {
    return findJsonStringEnd(source, start);
  }
  if (source[start] === "{" || source[start] === "[") {
    const closers = [source[start] === "{" ? "}" : "]"];
    let position = start + 1;
    while (position < source.length && closers.length > 0) {
      if (source[position] === "\"") {
        position = findJsonStringEnd(source, position);
      } else {
        if (source[position] === "{") closers.push("}");
        if (source[position] === "[") closers.push("]");
        if (source[position] === closers[closers.length - 1]) closers.pop();
        position++;
      }
    }
    return position;
  }

  let position = start;
  while (
    position < source.length &&
    source[position] !== "," &&
    source[position] !== "}"
  ) {
    position++;
  }
  return position;
}

function skipWhitespace(source: string, start: number): number {
  let position = start;
  while (/\s/.test(source[position] ?? "")) position++;
  return position;
}

export function parseArbSource(source: string): Record<string, unknown> {
  // JSON.parse keeps only the final duplicate property. Scan the raw source as
  // well so conflicting inspirational quote keys cannot be silently replaced.
  const parsed: unknown = JSON.parse(source);
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("ARB source must contain a JSON object");
  }

  const quoteValues = new Map<string, string>();
  let position = skipWhitespace(source, 0);
  position = skipWhitespace(source, position + 1);
  while (source[position] !== "}") {
    const keyEnd = findJsonStringEnd(source, position);
    const key = JSON.parse(source.slice(position, keyEnd)) as string;
    position = skipWhitespace(source, keyEnd);
    position = skipWhitespace(source, position + 1);
    const valueEnd = findJsonValueEnd(source, position);

    if (QUOTE_KEY_PATTERN.test(key)) {
      const value: unknown = JSON.parse(source.slice(position, valueEnd));
      if (typeof value !== "string") {
        throw new Error(`${key} must be a string`);
      }
      const previousValue = quoteValues.get(key);
      if (previousValue !== undefined && previousValue !== value) {
        throw new Error(
          `Conflicting duplicate inspirational quote key: ${key}`,
        );
      }
      quoteValues.set(key, value);
    }

    position = skipWhitespace(source, valueEnd);
    if (source[position] === ",") {
      position = skipWhitespace(source, position + 1);
    }
  }

  return parsed as Record<string, unknown>;
}

export function parseGenderSelect(message: string): GenderVariants {
  const header = message.match(/^\{gender\s*,\s*select\s*,/);
  if (!header) {
    throw new Error("Expected a gender select ICU message");
  }
  if (message[message.length - 1] !== "}") {
    throw new Error("Expected an outer closing brace");
  }

  const variants = new Map<string, string>();
  const outerClosingBrace = message.length - 1;
  let position = header[0].length;
  while (position < outerClosingBrace) {
    while (/\s/.test(message[position] ?? "")) position++;
    if (position === outerClosingBrace) break;
    const nameMatch = message.slice(position).match(/^([A-Za-z]+)\s*\{/);
    if (!nameMatch) {
      throw new Error("Invalid gender variant in ICU message");
    }

    const name = nameMatch[1];
    position += nameMatch[0].length;
    const contentStart = position;
    let depth = 1;
    while (position < message.length && depth > 0) {
      if (message[position] === "{") depth++;
      if (message[position] === "}") depth--;
      position++;
    }
    if (depth !== 0) {
      throw new Error("Unbalanced braces in ICU message");
    }
    if (position > outerClosingBrace) {
      throw new Error("Expected an outer closing brace");
    }
    variants.set(name, message.slice(contentStart, position - 1));
  }

  const male = variants.get("male");
  const female = variants.get("female");
  const other = variants.get("other");
  if (male === undefined || female === undefined || other === undefined) {
    throw new Error("Gender select must define male, female, and other");
  }
  return { male, female, other };
}

export function buildNotificationSeed(
  arbByLocale: Record<Locale, Record<string, unknown>>,
): SeedDocument[] {
  const documents: SeedDocument[] = [
    {
      collection: "notification_types",
      id: "default",
      data: {
        id: "default",
        messageType: "dynamic",
        quotesCollections: {
          he: "quotes_he",
          ar: "quotes_ar",
          en: "quotes_en",
        },
      },
    },
  ];

  for (const locale of LOCALES) {
    const quotes = Object.entries(arbByLocale[locale])
      .flatMap(([key, value]) => {
        const match = key.match(QUOTE_KEY_PATTERN);
        if (!match) return [];
        if (typeof value !== "string") {
          throw new Error(`${key} in app_${locale}.arb must be a string`);
        }
        return [{ key, index: Number(match[1]), value }];
      })
      .sort((left, right) => left.index - right.index);

    if (quotes.length === 0) {
      throw new Error(`No inspirational quotes found in app_${locale}.arb`);
    }

    for (const quote of quotes) {
      documents.push({
        collection: `quotes_${locale}`,
        id: quote.key,
        data: parseGenderSelect(quote.value),
      });
    }
  }

  return documents;
}

export async function provisionNotificationContent(
  documents: SeedDocument[],
  writer: SeedWriter,
): Promise<void> {
  for (const document of documents) {
    await writer.setDocument(document);
  }
}
