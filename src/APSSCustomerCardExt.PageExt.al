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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Test a REST API POST request.';

                trigger OnAction()
                var
                    RestApiManagement: Codeunit "APSS REST API Management";
                begin
                    RestApiManagement.SendDataToExternalApi(Rec."No.", Rec.Name);
                end;
            }
            action(APSS_ExternalUsers)
            {
                ApplicationArea = All;
                Caption = 'External Users';
                Image = Users;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "APSS External Users";
                ToolTip = 'View and synchronize users from the external REST API.';
            }
        }
    }
}
