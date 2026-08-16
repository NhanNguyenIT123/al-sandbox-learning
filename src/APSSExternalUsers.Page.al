page 50149 "APSS External Users"
{
    ApplicationArea = All;
    Caption = 'External Users';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    CardPageId = "APSS External User Card";
    SourceTable = "APSS External User";
    SourceTableView = sorting("External ID") order(ascending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Users)
            {
                field("External ID"; Rec."External ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user identifier supplied by the external API.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external user''s full name.';
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external user''s sign-in name.';
                }
                field("E-mail"; Rec."E-mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external user''s e-mail address.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external user''s phone number.';
                }
                field(Website; Rec.Website)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external user''s website.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external user''s company.';
                }
                field(Street; Rec.Street)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the street in the external user''s address.';
                }
                field(Suite; Rec.Suite)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the suite in the external user''s address.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the city in the external user''s address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the post code in the external user''s address.';
                }
                field(Latitude; Rec.Latitude)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the latitude supplied by the external API.';
                    Visible = false;
                }
                field(Longitude; Rec.Longitude)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the longitude supplied by the external API.';
                    Visible = false;
                }
                field("Last Synced At"; Rec."Last Synced At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this record was most recently synchronized.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDetails)
            {
                ApplicationArea = All;
                Caption = 'Open Details';
                Image = View;
                RunObject = page "APSS External User Card";
                RunPageLink = "External ID" = field("External ID");
                ToolTip = 'Open a detailed view of the selected external user.';
            }
            action(Synchronize)
            {
                ApplicationArea = All;
                Caption = 'Synchronize';
                Image = Refresh;
                ToolTip = 'Fetch and synchronize users from the external REST API.';

                trigger OnAction()
                var
                    RestApiManagement: Codeunit "APSS REST API Management";
                    DeletedCount: Integer;
                    InsertedCount: Integer;
                    ModifiedCount: Integer;
                begin
                    RestApiManagement.SyncExternalUsers(InsertedCount, ModifiedCount, DeletedCount);
                    CurrPage.Update(false);
                    Message(SyncCompletedMsg, InsertedCount, ModifiedCount, DeletedCount);
                end;
            }
            action(ClearAllUsers)
            {
                ApplicationArea = All;
                Caption = 'Clear All Users';
                Image = Delete;
                ToolTip = 'Delete all synchronized external users so the import can be demonstrated again.';

                trigger OnAction()
                var
                    ExternalUser: Record "APSS External User";
                    RestApiManagement: Codeunit "APSS REST API Management";
                    DeletedCount: Integer;
                begin
                    if ExternalUser.IsEmpty() then begin
                        Message(NoUsersMsg);
                        exit;
                    end;

                    if not Confirm(ClearAllUsersQst, false, ExternalUser.Count()) then
                        exit;

                    DeletedCount := RestApiManagement.ClearExternalUsers();
                    CurrPage.Update(false);
                    Message(ClearCompletedMsg, DeletedCount);
                end;
            }
        }
        area(Promoted)
        {
            actionref(OpenDetails_Promoted; OpenDetails)
            {
            }
            actionref(Synchronize_Promoted; Synchronize)
            {
            }
        }
    }

    var
        ClearAllUsersQst: Label 'Delete all %1 synchronized external users?', Comment = '%1 = number of external user records';
        ClearCompletedMsg: Label '%1 external users were deleted.', Comment = '%1 = number of deleted external user records';
        NoUsersMsg: Label 'There are no external users to delete.';
        SyncCompletedMsg: Label 'Synchronization completed. Inserted: %1, updated: %2, deleted: %3.', Comment = '%1 = inserted record count, %2 = updated record count, %3 = deleted record count';
}
