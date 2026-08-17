table 50112 "APSS API Error Log"
{
    Caption = 'APSS API Error Log';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(2; "API Name"; Code[100])
        {
            Caption = 'API Name';
            DataClassification = SystemMetadata;
        }

        field(3; "Error Type"; Code[30])
        {
            Caption = 'Error Type';
            DataClassification = SystemMetadata;
        }

        field(4; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = ToBeClassified;
        }

        field(5; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = SystemMetadata;
        }

        field(6; "External Todo ID"; Integer)
        {
            Caption = 'External Todo ID';
            DataClassification = ToBeClassified;
        }

        field(7; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}