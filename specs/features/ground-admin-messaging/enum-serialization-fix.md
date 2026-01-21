# Enum Serialization Fix - Multi-App Coordination

## Problem Summary

The backend has two related enum handling issues:

### Issue 1: JSON Serialization (FIXED)
The backend was serializing enums using their Kotlin constant names (UPPERCASE) instead of lowercase snake_case.
- Backend sent: `type: "GROUND_ADMIN_INVITATION"`, `status: "UNREAD"`
- Clients expected: `type: "ground_admin_invitation"`, `status: "unread"`
- **Status:** Fixed with `@JsonValue` annotation

### Issue 2: Query Parameter Binding (CURRENT)
The backend rejects lowercase enum values in query parameters:
```
GET /api/v1/messages?status=unread&size=1
→ 400 BAD_REQUEST: Invalid value for parameter: status, value: unread
```

Spring MVC's default enum converter expects exact enum constant names (`UNREAD`), but clients send lowercase (`unread`).

**Error from logs:**
```json
{"error": {"code": "VALIDATION_ERROR", "message": "Invalid value for parameter: status", "details": {"parameter": "status", "value": "unread"}}}
```

## Root Cause

1. **JSON:** Jackson uses enum constant name by default → Fixed with `@JsonValue`
2. **Query params:** Spring MVC uses `Enum.valueOf()` which is case-sensitive → Needs custom converter

## Affected Enums

| Enum | File | Current Output | Expected Output |
|------|------|----------------|-----------------|
| `MessageType` | `backend/.../shared/enums/MessageType.kt` | `GROUND_ADMIN_INVITATION` | `ground_admin_invitation` |
| `MessageStatus` | `backend/.../shared/enums/MessageStatus.kt` | `UNREAD` | `unread` |

## Expected API Format (Contract)

All clients (web and mobile) expect **lowercase snake_case** for enum values in JSON:

```json
{
  "type": "ground_admin_invitation",
  "status": "unread"
}
```

This matches both:
- Web types: `web/src/shared/types/message.ts`
- Mobile types: `mobile/lib/shared/models/message.dart`

---

## Fix Instructions by App

### Backend (Required - Source of Truth)

**File 1:** `backend/src/main/kotlin/com/munserv/shared/enums/MessageType.kt`

```kotlin
package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonValue

enum class MessageType(
    @JsonValue private val apiString: String,  // ADD @JsonValue here
) {
    GROUND_ADMIN_INVITATION("ground_admin_invitation"),
    // ... rest unchanged
    ;

    fun toApiString(): String = apiString

    companion object {
        @JsonCreator  // ADD this annotation
        @JvmStatic    // ADD this annotation
        fun fromString(value: String): MessageType =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown MessageType: $value")
    }
}
```

**File 2:** `backend/src/main/kotlin/com/munserv/shared/enums/MessageStatus.kt`

```kotlin
package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonValue

enum class MessageStatus(
    @JsonValue private val apiString: String,  // ADD @JsonValue here
) {
    UNREAD("unread"),
    READ("read"),
    ACTIONED("actioned"),
    DISMISSED("dismissed"),
    ;

    fun toApiString(): String = apiString

    companion object {
        @JsonCreator  // ADD this annotation
        @JvmStatic    // ADD this annotation
        fun fromString(value: String): MessageStatus =
            entries.find { it.apiString.equals(value, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown MessageStatus: $value")
    }
}
```

**Changes Summary for Enums:**
1. Add `import com.fasterxml.jackson.annotation.JsonCreator`
2. Add `import com.fasterxml.jackson.annotation.JsonValue`
3. Add `@JsonValue` annotation to the `apiString` property
4. Add `@JsonCreator` and `@JvmStatic` annotations to the `fromString` companion function

---

### Backend Fix Part 2: Query Parameter Converters

Spring MVC needs custom converters to handle lowercase enum values in query parameters.

**File 3:** Create `backend/src/main/kotlin/com/munserv/shared/config/EnumConverters.kt`

```kotlin
package com.munserv.shared.config

import com.munserv.shared.enums.MessageStatus
import com.munserv.shared.enums.MessageType
import org.springframework.core.convert.converter.Converter
import org.springframework.stereotype.Component

/**
 * Converter for MessageStatus query parameters.
 * Accepts lowercase snake_case values (e.g., "unread" → UNREAD).
 */
@Component
class MessageStatusConverter : Converter<String, MessageStatus> {
    override fun convert(source: String): MessageStatus =
        MessageStatus.fromString(source)
}

/**
 * Converter for MessageType query parameters.
 * Accepts lowercase snake_case values (e.g., "ground_admin_invitation" → GROUND_ADMIN_INVITATION).
 */
@Component
class MessageTypeConverter : Converter<String, MessageType> {
    override fun convert(source: String): MessageType =
        MessageType.fromString(source)
}
```

The converters use the existing `fromString()` methods which already handle case-insensitive matching.

**Alternative:** Register converters explicitly in a WebMvcConfigurer if @Component doesn't auto-register:

```kotlin
package com.munserv.shared.config

import org.springframework.context.annotation.Configuration
import org.springframework.format.FormatterRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class WebConfig : WebMvcConfigurer {
    override fun addFormatters(registry: FormatterRegistry) {
        registry.addConverter(MessageStatusConverter())
        registry.addConverter(MessageTypeConverter())
    }
}
```

---

**Verification:**
```bash
cd backend
./gradlew test
./gradlew bootRun

# Test JSON response (lowercase output)
curl http://localhost:8080/api/v1/messages -H "Authorization: Bearer <token>"
# Verify: "type": "ground_admin_invitation", "status": "unread"

# Test query parameter (lowercase input)
curl "http://localhost:8080/api/v1/messages?status=unread&size=1" -H "Authorization: Bearer <token>"
# Should return 200 OK, not 400 BAD_REQUEST
```

---

### Web (No Changes Required)

The web types in `web/src/shared/types/message.ts` already expect lowercase snake_case:

```typescript
export type MessageType =
  | 'ground_admin_invitation'
  | 'ground_admin_application'
  // ...

export type MessageStatus = 'unread' | 'read' | 'actioned' | 'dismissed';
```

Once the backend fix is deployed, web will work correctly.

---

### Mobile (No Changes Required)

The mobile types in `mobile/lib/shared/models/message.dart` already expect lowercase snake_case:

```dart
enum MessageType {
  @JsonValue('ground_admin_invitation')
  groundAdminInvitation,
  // ...
}

enum MessageStatus {
  unread,
  read,
  actioned,
  dismissed;
}
```

Once the backend fix is deployed, mobile will work correctly.

**Note:** If mobile has auto-generated files, regenerate after confirming backend fix:
```bash
cd mobile
dart run build_runner build --delete-conflicting-outputs
```

---

## Verification Checklist

After backend fix is deployed:

- [ ] Backend unit tests pass: `./gradlew test`
- [ ] API returns lowercase enums in JSON response: `curl /api/v1/messages`
- [ ] API accepts lowercase enums in query params: `curl /api/v1/messages?status=unread`
- [ ] Web messages page loads correctly
- [ ] Mobile messages tab loads without errors
- [ ] Mobile unread badge count works (uses `?status=unread` query)
- [ ] Ground Admin invitation messages display properly
- [ ] Accept/Decline actions work correctly

## Additional Enums to Audit

Check if any other enums in `backend/src/main/kotlin/com/munserv/shared/enums/` need the same fix:

```bash
ls backend/src/main/kotlin/com/munserv/shared/enums/
```

Each enum with an `apiString` pattern should have `@JsonValue` and `@JsonCreator` annotations.

---

## Timeline

1. **Backend fix** - Required first (blocks web and mobile)
2. **Web verification** - Test after backend deployed
3. **Mobile verification** - Test after backend deployed

No code changes needed in web or mobile - only verification testing.
