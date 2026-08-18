# Will - External Users Integration Architecture

## Purpose

This extension synchronizes users from the JSONPlaceholder `/users` endpoint into Microsoft Dynamics 365 Business Central. Assignment 2 adds persistent error logging and fault-tolerant processing so handled API and user validation failures do not terminate the synchronization action.

## AL Objects

| Object | ID | Responsibility |
| --- | ---: | --- |
| `APSS REST API Management` codeunit | 50100 | Calls the API, validates JSON, synchronizes users, and writes handled failures to the error log. |
| `APSS API Error Log` table | 50147 | Stores HTTP, response, and item-validation error details. |
| `APSS API Error Log` page | 50147 | Displays logged errors and provides a controlled Clear Log action. |
| `APSS External User Card` page | 50148 | Displays one synchronized user. |
| `APSS External User` table | 50149 | Stores typed external-user data using External ID as the primary key. |
| `APSS External Users` page | 50149 | Starts synchronization and displays users, result counts, and the Error Log action. |
| `APSS REST API` permission set | 50149 | Grants read access to stored data and execute access to the integration objects. |

## Synchronization Flow

1. `APSS External Users` calls `SyncExternalUsers` in the management codeunit.
2. The codeunit sends an HTTP GET request to `https://jsonplaceholder.typicode.com/users`.
3. A transport failure or non-success HTTP status is written to `APSS API Error Log`; the procedure then exits without raising an error.
4. A successful response is parsed one item at a time into a temporary `APSS External User` record set.
5. `TryParseExternalUser` catches item-level validation errors. A user with a missing or empty email is logged and skipped while the remaining users continue through the loop.
6. Valid temporary users are inserted or refreshed in the stored table by External ID.
7. Stored users missing from the response are deleted only when every response item was valid. If any item failed validation, delete reconciliation is skipped to prevent accidental data loss.
8. The page reports inserted, updated, deleted, and logged-error counts.

## Error Log Design

Each entry contains:

- Occurrence date and time
- API resource and operation
- Endpoint
- External record ID and JSON array index when available
- HTTP status code when available
- Error category and detailed message

The integration currently uses these categories:

- `HTTP`: transport failures and non-success HTTP status codes
- `Response`: unreadable, invalid, or empty response bodies
- `Validation`: invalid individual user records, including missing emails

The Error Log page is read-only. Insert and delete operations are performed through the management codeunit so table writes remain controlled.

## Data-Safety Decisions

- API data is parsed into a temporary table before stored users are updated.
- A bad user does not terminate processing of later users.
- A payload containing any invalid item cannot trigger deletion of stored users.
- HTTP and response-level failures leave the existing user table unchanged.
- Error messages are limited to the size of the log field before insertion.

## Demonstration

1. Open **External Users** and choose **Synchronize**.
2. Review the inserted, updated, deleted, and errors-logged counts.
3. Choose **API Error Log** to inspect handled failures.
4. Use **Clear Log** when a clean error-log demonstration is required.
5. Choose **Simulate 404 Error** or **Simulate 500 Error** on the External Users page to add deterministic demo entries without depending on a failing external service.

The simulation actions use the same HTTP status logging path as a real non-success response. They do not send an external request, and each log message explicitly identifies the entry as simulated.

Outbound calls require **Allow HttpClient Requests** to be enabled for the extension.
