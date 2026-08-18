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
