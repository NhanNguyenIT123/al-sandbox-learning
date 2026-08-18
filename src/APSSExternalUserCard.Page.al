page 50148 "APSS External User Card"
{
    ApplicationArea = All;
    Caption = 'External User Details';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "APSS External User";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
            }
            group(Contact)
            {
                Caption = 'Contact';

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
            }
            group(Address)
            {
                Caption = 'Address';

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
                }
                field(Longitude; Rec.Longitude)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the longitude supplied by the external API.';
                }
            }
            group(Synchronization)
            {
                Caption = 'Synchronization';

                field("Last Synced At"; Rec."Last Synced At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this record was most recently synchronized.';
                }
            }
        }
    }
}
