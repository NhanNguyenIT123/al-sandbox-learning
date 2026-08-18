table 50147 "APSS API Error Log"
{
    Caption = 'API Error Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Occurred At"; DateTime)
        {
            Caption = 'Occurred At';
        }
        field(3; "API Resource"; Text[50])
        {
            Caption = 'API Resource';
        }
        field(4; Operation; Text[50])
        {
            Caption = 'Operation';
        }
        field(5; Endpoint; Text[250])
        {
            Caption = 'Endpoint';
            ExtendedDatatype = URL;
        }
        field(6; "External Record ID"; Integer)
        {
            Caption = 'External Record ID';
        }
        field(7; "Array Index"; Integer)
        {
            Caption = 'Array Index';
        }
        field(8; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
        }
        field(9; "Error Type"; Text[50])
        {
            Caption = 'Error Type';
        }
        field(10; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(OccurredAt; "Occurred At")
        {
        }
    }
}
