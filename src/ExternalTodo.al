table 50110 "APSS External Todo"
{
    Caption = 'APSS External Todo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "External Todo ID"; Integer)
        {
            Caption = 'External Todo ID';
            DataClassification = CustomerContent;
        }

        field(2; "External User ID"; Integer)
        {
            Caption = 'External User ID';
            DataClassification = CustomerContent;
        }

        field(3; Title; Text[250])
        {
            Caption = 'Title';
            DataClassification = CustomerContent;
        }

        field(4; Completed; Boolean)
        {
            Caption = 'Completed';
            DataClassification = CustomerContent;
        }

        field(5; "Last Synced At"; DateTime)
        {
            Caption = 'Last Synced At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "External Todo ID")
        {
            Clustered = true;
        }
    }
}