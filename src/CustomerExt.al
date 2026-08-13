tableextension 50100 "APSS Customer Ext" extends Customer
{
    fields
    {
        field(50100; "APSS External ID"; Text[50])
        {
            Caption = 'APSS External ID';
            DataClassification = CustomerContent;
        }
    }
}

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
                ToolTip = 'Test a REST API GET Request.';

                trigger OnAction()
                var
                    RestApiMgt: Codeunit "APSS REST API Management";
                begin
                    RestApiMgt.FetchExternalData();
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
                ToolTip = 'Test a REST API POST Request.';

                trigger OnAction()
                var
                    RestApiMgt: Codeunit "APSS REST API Management";
                begin
                    RestApiMgt.SendDataToExternalApi(Rec."No.", Rec.Name);
                end;
            }
        }
    }
}
