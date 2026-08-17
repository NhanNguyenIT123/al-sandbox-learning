page 50113 "APSS API Error Log List"
{
    Caption = 'APSS API Error Logs';
    PageType = List;
    SourceTable = "APSS API Error Log";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("API Name"; Rec."API Name")
                {
                    ApplicationArea = All;
                }

                field("Error Type"; Rec."Error Type")
                {
                    ApplicationArea = All;
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }

                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                }

                field("External Todo ID"; Rec."External Todo ID")
                {
                    ApplicationArea = All;
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllLogs)
            {
                ApplicationArea = All;
                Caption = 'Delete All Logs';
                Image = Delete;

                trigger OnAction()
                var
                    APIErrorLogMgt: Codeunit "APSS API Error Log Mgt.";
                begin
                    if not Confirm(
                        'Are you sure you want to delete all API error logs?')
                    then
                        exit;

                    APIErrorLogMgt.DeleteAllLogs();
                    CurrPage.Update(false);
                end;
            }

            action(ExportLogs)
            {
                ApplicationArea = All;
                Caption = 'Export';
                Image = Export;

                trigger OnAction()
                var
                    APIErrorLogMgt: Codeunit "APSS API Error Log Mgt.";
                begin
                    APIErrorLogMgt.ExportLogs();
                end;
            }
        }
    }
}