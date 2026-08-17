page 50111 "APSS External Todo List"
{
    Caption = 'APSS External Todos';
    PageType = List;
    SourceTable = "APSS External Todo";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("External Todo ID"; Rec."External Todo ID")
                {
                    ToolTip = 'Specifies the Todo identifier from the external API.';
                }

                field("External User ID"; Rec."External User ID")
                {
                    ToolTip = 'Specifies the user identifier from the external API.';
                }

                field(Title; Rec.Title)
                {
                    ToolTip = 'Specifies the Todo title from the external API.';
                }

                field(Completed; Rec.Completed)
                {
                    ToolTip = 'Specifies whether the Todo is completed.';
                }

                field("Last Synced At"; Rec."Last Synced At")
                {
                    ToolTip = 'Specifies when the Todo was last synchronized from the external API.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportTodos)
            {
                ApplicationArea = All;
                Caption = 'Import Todos';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Fetches Todo records from the external API and updates the list.';

                trigger OnAction()
                var
                    RestApiMgt: Codeunit "APSS REST API Management";
                begin
                    RestApiMgt.FetchTodoCollection();
                    CurrPage.Update(false);
                end;
            }

            action(TestInvalidTodo)
            {
                ApplicationArea = All;
                Caption = 'Test Invalid Todo';
                Image = TestDatabase;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Runs a test with an invalid Todo record to verify error logging and continued processing.';

                trigger OnAction()
                var
                    TodoTest: Codeunit "APSS Todo Test";
                begin
                    TodoTest.TestInvalidTodoHandling();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}