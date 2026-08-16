permissionset 50149 "APSS REST API"
{
    Assignable = true;
    Caption = 'APSS REST API';

    Permissions =
        tabledata "APSS External User" = R,
        table "APSS External User" = X,
        page "APSS External User Card" = X,
        page "APSS External Users" = X,
        codeunit "APSS REST API Management" = X;
}
