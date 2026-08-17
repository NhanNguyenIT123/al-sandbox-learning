codeunit 50114 "APSS API Error Log Mgt."
{
    /// <summary>
    /// Logs an HTTP or transport error from an external API request.
    /// </summary>
    procedure LogHttpError(
        APIName: Code[100];
        ErrorMessage: Text;
        HTTPStatusCode: Integer)
    begin
        InsertErrorLog(
            APIName,
            'HTTP',
            ErrorMessage,
            HTTPStatusCode,
            0);
    end;

    /// <summary>
    /// Logs a validation error for an external Todo record.
    /// </summary>
    procedure LogValidationError(
        APIName: Code[100];
        ErrorMessage: Text;
        ExternalTodoID: Integer)
    begin
        InsertErrorLog(
            APIName,
            'VALIDATION',
            ErrorMessage,
            0,
            ExternalTodoID);
    end;

    /// <summary>
    /// Deletes all API error log entries.
    /// </summary>
    procedure DeleteAllLogs()
    var
        APIErrorLog: Record "APSS API Error Log";
    begin
        APIErrorLog.DeleteAll();
    end;

    /// <summary>
    /// Exports all API error log entries to a CSV file.
    /// </summary>
    procedure ExportLogs()
    var
        APIErrorLog: Record "APSS API Error Log";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
        Line: Text;
    begin
        APIErrorLog.Reset();
        APIErrorLog.SetCurrentKey("Entry No.");

        TempBlob.CreateOutStream(
            OutStream,
            TextEncoding::UTF8);

        Line :=
            'Entry No.,API Name,Error Type,Error Message,HTTP Status Code,External Todo ID,Created At';

        OutStream.WriteText(Line);
        OutStream.WriteText();

        if APIErrorLog.FindSet() then
            repeat
                Line :=
                    StrSubstNo(
                        '%1,%2,%3,%4,%5,%6,%7',
                        APIErrorLog."Entry No.",
                        EscapeCsvValue(APIErrorLog."API Name"),
                        EscapeCsvValue(APIErrorLog."Error Type"),
                        EscapeCsvValue(APIErrorLog."Error Message"),
                        APIErrorLog."HTTP Status Code",
                        APIErrorLog."External Todo ID",
                        APIErrorLog."Created At");

                OutStream.WriteText(Line);
                OutStream.WriteText();
            until APIErrorLog.Next() = 0;

        TempBlob.CreateInStream(
            InStream,
            TextEncoding::UTF8);

        FileName := 'APSS_API_Error_Log.csv';

        DownloadFromStream(
            InStream,
            'Export API Error Logs',
            '',
            'CSV Files (*.csv)|*.csv',
            FileName);
    end;

    local procedure InsertErrorLog(
        APIName: Code[100];
        ErrorType: Code[30];
        ErrorMessage: Text;
        HTTPStatusCode: Integer;
        ExternalTodoID: Integer)
    var
        APIErrorLog: Record "APSS API Error Log";
    begin
        APIErrorLog.Init();

        APIErrorLog."API Name" :=
            APIName;

        APIErrorLog."Error Type" :=
            ErrorType;

        APIErrorLog."Error Message" :=
            CopyStr(
                ErrorMessage,
                1,
                MaxStrLen(
                    APIErrorLog."Error Message"));

        APIErrorLog."HTTP Status Code" :=
            HTTPStatusCode;

        APIErrorLog."External Todo ID" :=
            ExternalTodoID;

        APIErrorLog."Created At" :=
            CurrentDateTime();

        APIErrorLog.Insert(true);
    end;

    local procedure EscapeCsvValue(
        Value: Text): Text
    begin
        Value :=
            Value.Replace(
                '"',
                '""');

        exit(
            '"' +
            Value +
            '"');
    end;
}