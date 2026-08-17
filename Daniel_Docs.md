# Daniel - Assignment 2 Documentation

## 1. Overview

Assignment 2 extends the REST API Todo integration from Assignment 1.

The main goal is to make the Todo synchronization more robust by handling API failures and invalid Todo data without crashing the synchronization process.

The solution uses JSONPlaceholder as the external REST API for training and testing purposes.

---

## 2. Architecture

The Todo synchronization flow is:

```text
External REST API
        |
        v
HttpClient
        |
        v
APSS REST API Management
        |
        v
JSON Array Parser
        |
        v
Validation
        |
        +--------------------+
        |                    |
      Valid                Invalid
        |                    |
        v                    v
Temporary Record       API Error Log
        |                    |
        v                    |
APSS External Todo      Continue
        |
        v
APSS External Todo List

Main Components
Component	Responsibility
APSS REST API Management	Calls the external API and manages Todo synchronization
APSS Json Array Parser	Parses and validates the JSON Todo array
APSS External Todo	Stores synchronized Todo data
APSS External Todo List	Displays Todo records and provides the Import action
APSS API Error Log	Stores API and validation errors
APSS API Error Log List	Displays recorded API errors
APSS API Error Log Mgt.	Centralizes error log creation and log management
3. Todo Data Mapping

The external API Todo fields are mapped to Business Central as follows:

JSONPlaceholder	Business Central
id	External Todo ID
userId	External User ID
title	Title
completed	Completed

External Todo ID is used as the primary key.

4. Synchronization

The synchronization process is designed to be idempotent.

For each Todo:

If the Todo does not exist in Business Central, it is inserted.
If the Todo already exists, its data is updated.
Last Synced At is updated during synchronization.
The external Todo ID is used to identify existing records.

This allows the Todo collection to be imported multiple times without creating duplicate records.

5. Error Handling

Assignment 2 changes the synchronization behavior so that recoverable errors do not crash the entire synchronization process.

HTTP Errors

The REST API management code handles:

HTTP request failures
Non-success HTTP status codes
Empty response bodies
Response body read failures

These errors are written to the API Error Log instead of raising an unhandled error.

Example:

HTTP GET
    |
    +-- Request fails
    |      |
    |      v
    |   Log Error
    |
    +-- HTTP 404/500
           |
           v
        Log Error

The synchronization exits safely when the API itself cannot provide a usable response.

6. Invalid Todo Handling

Individual Todo records are validated while parsing the JSON array.

Validation includes:

Required userId
Required id
Positive integer values
Required title
Non-empty title
Title length validation
Required completed
Boolean type validation
Duplicate Todo ID detection

If an individual Todo is invalid:

Todo 1 -> Valid -> Process
Todo 2 -> Valid -> Process
Todo 3 -> Invalid -> Log Error -> Skip
Todo 4 -> Valid -> Process

The invalid record does not stop the processing of subsequent Todo records.

This is important because one bad external record should not prevent valid records from being synchronized.

7. API Error Log

The custom API Error Log stores information about synchronization failures.

The log contains information such as:

Entry number
API name
Error type
Error message
HTTP status code
External Todo ID
Created date/time

The Error Log page allows users to review synchronization problems from Business Central.

The management codeunit also provides functionality for:

Creating error log entries
Clearing logs
Deleting all logs
Exporting log information
8. Testing

The implementation was tested with both successful and failure scenarios.

Normal Todo Import

First import:

200 Todo records

Result:

200 records synchronized

Second import:

200 Todo records

Result:

No duplicate records created
Existing records updated
HTTP Error Test

A controlled invalid API endpoint was used to simulate an HTTP failure.

Result:

HTTP Status Code: 404
Error Type: HTTP
Error written to APSS API Error Logs
Synchronization did not crash
Invalid Todo Test

A controlled test payload was used containing an invalid Todo:

Todo 1 -> Valid
Todo 2 -> Valid
Todo 3 -> Invalid
Todo 4 -> Valid

Result:

Processed: 4
Successful: 3
Failed: 1

The invalid Todo was written to the API Error Log.

The test also confirmed that Todo 4 continued to be processed after Todo 3 failed.

Example error log:

Error Type: VALIDATION
External Todo ID: 3

The temporary test utility was removed after verification so that the production extension does not contain test-only actions.

9. Customer REST API Testing

The Customer Card extension retains the REST API training actions:

Test REST API GET
Test REST API POST

The GET action verifies communication with the external API.

The POST action sends customer information from Business Central to JSONPlaceholder.

Example POST response:

{
    "title": "Customer APSS-CUST-00168: NESTLE VIETNAM",
    "body": "Test data sent from Business Central",
    "userId": 1,
    "id": 101
}

Both GET and POST requests were successfully tested.

10. External API

JSONPlaceholder is currently used as the external API because this is a training and testing assignment.

The architecture is designed so that the external API can be replaced by a real API in a future implementation.

For a production integration, additional considerations would include:

Authentication
API credentials/secrets
Configuration instead of hard-coded URLs
Retry policies
Timeout handling
API versioning
Monitoring
Rate limiting
Production-specific error handling
11. Design Considerations

The implementation separates responsibilities between components:

REST API Management
        |
        +--> HTTP communication
        |
        +--> Synchronization
        |
        v
JSON Array Parser
        |
        +--> JSON parsing
        |
        +--> Data validation
        |
        v
Temporary Todo Records
        |
        v
External Todo Table

Error logging is handled by a dedicated management codeunit instead of duplicating log creation logic throughout the application.

This keeps the implementation easier to maintain and extend.

12. Summary

The Assignment 2 implementation provides:

REST API GET integration
REST API POST integration
JSON array parsing
Todo validation
Insert/update synchronization
Duplicate prevention
HTTP error logging
Invalid data logging
Continue-on-error behavior for individual Todo records
API Error Log table and page
Error log management
XML documentation comments
Architecture documentation

The implementation was tested with both successful API responses and controlled failure scenarios.