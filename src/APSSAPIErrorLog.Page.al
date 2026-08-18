page 50147 "APSS API Error Log"
{
    ApplicationArea = All;
    Caption = 'API Error Log';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "APSS API Error Log";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Errors)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique number of the API error log entry.';
                }
                field("Occurred At"; Rec."Occurred At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the API error occurred.';
                }
                field("API Resource"; Rec."API Resource")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API resource being processed when the error occurred.';
                }
                field(Operation; Rec.Operation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API operation that encountered the error.';
                }
                field("External Record ID"; Rec."External Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external record identifier, when available.';
                }
                field("Array Index"; Rec."Array Index")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the zero-based response array index, when available.';
                }
                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP status code returned by the API, when available.';
                }
                field("Error Type"; Rec."Error Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the category of the API error.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the details of the API error.';
                }
                field(Endpoint; Rec.Endpoint)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API endpoint used by the operation.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearLog)
            {
                ApplicationArea = All;
                Caption = 'Clear Log';
                Image = Delete;
                ToolTip = 'Delete all API error log entries.';

                trigger OnAction()
                var
                    ApiErrorLog: Record "APSS API Error Log";
                    RestApiManagement: Codeunit "APSS REST API Management";
                    DeletedCount: Integer;
                begin
                    if ApiErrorLog.IsEmpty() then begin
                        Message(NoEntriesMsg);
                        exit;
                    end;

                    if not Confirm(ClearLogQst, false, ApiErrorLog.Count()) then
                        exit;

                    DeletedCount := RestApiManagement.ClearApiErrorLog();
                    CurrPage.Update(false);
                    Message(ClearCompletedMsg, DeletedCount);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ClearLog_Promoted; ClearLog)
            {
            }
        }
    }

    var
        ClearCompletedMsg: Label '%1 API error log entries were deleted.', Comment = '%1 = number of deleted log entries';
        ClearLogQst: Label 'Delete all %1 API error log entries?', Comment = '%1 = number of log entries';
        NoEntriesMsg: Label 'There are no API error log entries to delete.';
}
