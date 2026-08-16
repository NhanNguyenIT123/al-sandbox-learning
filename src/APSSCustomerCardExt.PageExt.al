pageextension 50100 "APSS Customer Card Ext" extends "Customer Card"
{
    layout
    {
        addlast(General)
        {
            field("APSS External ID"; Rec."APSS External ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the APSS External ID for the customer.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(APSS_TestRestApiGet)
            {
                ApplicationArea = All;
                Caption = 'Test REST API GET';
                Image = Web;
                ToolTip = 'Test a REST API GET request.';

                trigger OnAction()
                var
                    RestApiManagement: Codeunit "APSS REST API Management";
                begin
                    RestApiManagement.FetchExternalData();
                end;
            }
            action(APSS_TestRestApiPost)
            {
                ApplicationArea = All;
                Caption = 'Test REST API POST';
                Image = Web;
                ToolTip = 'Test a REST API POST request.';

                trigger OnAction()
                var
                    RestApiManagement: Codeunit "APSS REST API Management";
                begin
                    RestApiManagement.SendDataToExternalApi();
                end;
            }
            action(APSS_ExternalUsers)
            {
                ApplicationArea = All;
                Caption = 'External Users';
                Image = Users;
                RunObject = page "APSS External Users";
                ToolTip = 'View and synchronize users from the external REST API.';
            }
        }
        addlast(Category_Process)
        {
            actionref(APSS_TestRestApiGet_Promoted; APSS_TestRestApiGet)
            {
            }
            actionref(APSS_TestRestApiPost_Promoted; APSS_TestRestApiPost)
            {
            }
            actionref(APSS_ExternalUsers_Promoted; APSS_ExternalUsers)
            {
            }
        }
    }
}
