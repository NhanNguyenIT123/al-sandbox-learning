permissionset 50149 "APSS REST API"
{
    Assignable = true;
    Caption = 'APSS REST API';

    Permissions =
        tabledata "APSS API Error Log" = R,
        table "APSS API Error Log" = X,
        tabledata "APSS External User" = R,
        table "APSS External User" = X,
        page "APSS API Error Log" = X,
        page "APSS External User Card" = X,
        page "APSS External Users" = X,
        codeunit "APSS REST API Management" = X;
}
