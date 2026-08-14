table 50101 "APSS External User"
{
    Caption = 'External User';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "External ID"; Integer)
        {
            Caption = 'External ID';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "User Name"; Text[50])
        {
            Caption = 'User Name';
        }
        field(4; "E-mail"; Text[100])
        {
            Caption = 'E-mail';
            ExtendedDatatype = EMail;
        }
        field(5; Phone; Text[50])
        {
            Caption = 'Phone';
            ExtendedDatatype = PhoneNo;
        }
        field(6; Website; Text[100])
        {
            Caption = 'Website';
            ExtendedDatatype = URL;
        }
        field(7; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(8; Street; Text[100])
        {
            Caption = 'Street';
        }
        field(9; Suite; Text[50])
        {
            Caption = 'Suite';
        }
        field(10; City; Text[50])
        {
            Caption = 'City';
        }
        field(11; "Post Code"; Text[20])
        {
            Caption = 'Post Code';
        }
        field(12; Latitude; Decimal)
        {
            Caption = 'Latitude';
            DecimalPlaces = 0 : 6;
        }
        field(13; Longitude; Decimal)
        {
            Caption = 'Longitude';
            DecimalPlaces = 0 : 6;
        }
        field(14; "Last Synced At"; DateTime)
        {
            Caption = 'Last Synced At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "External ID")
        {
            Clustered = true;
        }
        key(NameKey; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "External ID", Name, "E-mail")
        {
        }
    }
}
