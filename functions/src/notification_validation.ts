const NOTIFICATION_TYPE_ID_PATTERN = /^[A-Za-z0-9_-]{1,64}$/;

export type NotificationGender = "male" | "female" | "other";
export type NotificationLocale = "he" | "ar" | "en";

type DynamicNotificationType = {
  messageType: "dynamic";
  quotesCollections: Record<string, unknown>;
};

type StaticNotificationType = {
  messageType: "static";
  staticTitle: string;
  staticBody: string;
};

type ValidNotificationType = DynamicNotificationType | StaticNotificationType;

const GENERATED_QUOTE_COLLECTIONS: Record<NotificationLocale, string> = {
  he: "quotes_he",
  ar: "quotes_ar",
  en: "quotes_en",
};

export function isValidNotificationTypeId(value: unknown): value is string {
  return (
    typeof value === "string" && NOTIFICATION_TYPE_ID_PATTERN.test(value)
  );
}

export function isValidNotificationLocale(
  value: unknown,
): value is NotificationLocale {
  return value === "he" || value === "ar" || value === "en";
}

export function normalizeNotificationGender(
  value: unknown,
): NotificationGender {
  return value === "male" || value === "female" || value === "other"
    ? value
    : "other";
}

export function hasValidNotificationTypeSchema(
  value: unknown,
): value is ValidNotificationType {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const data = value as Record<string, unknown>;
  if (data.messageType === "dynamic") {
    const collections = data.quotesCollections;
    return (
      collections !== null &&
      typeof collections === "object" &&
      !Array.isArray(collections) &&
      (Object.entries(GENERATED_QUOTE_COLLECTIONS) as Array<
        [NotificationLocale, string]
      >).every(([locale, collection]) =>
        Object.prototype.hasOwnProperty.call(collections, locale) &&
        (collections as Record<string, unknown>)[locale] === collection,
      )
    );
  }
  if (data.messageType === "static") {
    return (
      typeof data.staticTitle === "string" &&
      typeof data.staticBody === "string"
    );
  }
  return false;
}
