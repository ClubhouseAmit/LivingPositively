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

/**
 * True when a verified ID token was minted by Firebase Anonymous
 * Authentication. Reminders are a non-anonymous-only feature (FCM-05), and
 * security rules cannot express that: the notification collections deny all
 * direct client access, so the check has to happen here. The Flutter client
 * refuses to fetch a token for an anonymous user, but a client-side check is
 * a policy, not a control -- the endpoint is reachable directly.
 * See docs/adr/ADR-015 decision 5.
 */
export function isAnonymousSignIn(decodedToken: unknown): boolean {
  if (decodedToken === null || typeof decodedToken !== "object") return false;
  const firebaseClaim = (decodedToken as Record<string, unknown>).firebase;
  if (firebaseClaim === null || typeof firebaseClaim !== "object") return false;
  const provider =
    (firebaseClaim as Record<string, unknown>).sign_in_provider;
  return provider === "anonymous";
}

export function isValidNotificationTypeId(value: unknown): value is string {
  return (
    typeof value === "string" && NOTIFICATION_TYPE_ID_PATTERN.test(value)
  );
}

export function isValidNotificationUid(value: unknown): value is string {
  return (
    typeof value === "string" &&
    value.length > 0 &&
    value !== "." &&
    value !== ".." &&
    !value.includes("/")
  );
}

export function isValidNotificationLocale(
  value: unknown,
): value is NotificationLocale {
  return value === "he" || value === "ar" || value === "en";
}

/** Validates a wall-clock reminder time before it is persisted. */
export function isValidNotificationScheduleTime(
  hour: unknown,
  minute: unknown,
): boolean {
  return (
    typeof hour === "number" &&
    Number.isFinite(hour) &&
    Number.isInteger(hour) &&
    hour >= 0 &&
    hour <= 23 &&
    typeof minute === "number" &&
    Number.isFinite(minute) &&
    Number.isInteger(minute) &&
    minute >= 0 &&
    minute <= 59
  );
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
