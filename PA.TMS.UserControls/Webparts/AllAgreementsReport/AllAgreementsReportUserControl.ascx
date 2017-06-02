<%@ Assembly Name="$SharePoint.Project.AssemblyFullName$" %>
<%@ Assembly Name="Microsoft.Web.CommandUI, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> 
<%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> 
<%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Register Tagprefix="asp" Namespace="System.Web.UI" Assembly="System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" %>
<%@ Import Namespace="Microsoft.SharePoint" %> 
<%@ Register Tagprefix="WebPartPages" Namespace="Microsoft.SharePoint.WebPartPages" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="AllAgreementsReportUserControl.ascx.cs" Inherits="PA.TMS.UserControls.Webparts.AllAgreementsReport.AllAgreementsReportUserControl" %>

<style type="text/css">


/* Overdue Action Items Grid CSS*/
.tMSReoprtGrd {   
    width: 100%;   
    background-color: #fff;   
    margin: 5px 0 10px 0;   
    border: solid 1px #525252;   
    border-collapse:collapse;   
}  
.tMSReoprtGrd td {   
    padding: 2px;   
    border: solid 1px #c1c1c1;   
    color: #717171;   
}  
.tMSReoprtGrd th
{
    padding: 4px 2px;
    color: Black;
    background: #A9D8ED repeat-x top;
    border-left: solid 1px #525252;
    font-size: 0.9em;
}  
.tMSReoprtGrd .alt { background: #fcfcfc url(grd_alt.png) repeat-x top; }  
.tMSReoprtGrd .pgr
{
    background: #990000 repeat-x top;
}  
.tMSReoprtGrd .pgr table { margin: 5px 0; }  
.tMSReoprtGrd .pgr td {   
    border-width: 0;   
    padding: 0 6px;   
    border-left: solid 1px #666;   
    font-weight: bold;   
    color: #fff;   
    line-height: 12px;   
 }     
.tMSReoprtGrd .pgr a { color: #666; text-decoration: none; }  
.tMSReoprtGrd.pgr a:hover { color: #000; text-decoration: none; }
.tMSReoprtGrd tr:hover
{
    background-color: #CFD1D1;
    color: black;
}

</style>

<table cellpadding="0" cellspacing="0">
    <tr>
    <!--
        <td class="ms-formlabel">
            From Date
        </td>
        <td class="ms-formbody">
            <SharePoint:DateTimeControl ID="dtpFromDate" runat="server" DateOnly="true" LocaleId="2057">
            </SharePoint:DateTimeControl>
        </td>
        <td class="ms-formlabel">
            To Date
        </td>
        <td class="ms-formbody">
            <SharePoint:DateTimeControl ID="dtpToDate" runat="server" DateOnly="true" LocaleId="2057">
            </SharePoint:DateTimeControl>
        </td>
        -->
        <td colspan="3" class="ms-formlabel" style="text-align: right; padding: 15px;">
            <asp:Label ID="Label1" runat="server" Text=" CC Name :  " Font-Bold="true" Visible="true"></asp:Label>
            <asp:DropDownList ID="ddlCCName" runat="server" Visible="true" OnSelectedIndexChanged="ddlCCName_SelectedIndexChanged" AutoPostBack="true">
            </asp:DropDownList>
        </td>
        <td class="ms-formlabel" style="text-align: right; padding: 15px;">
            <asp:Label ID="lblType" runat="server" Text=" Active/Inactive :  " Font-Bold="true" Visible="true"></asp:Label>
            <asp:DropDownList ID="ddlType" runat="server" Visible="true" OnSelectedIndexChanged="ddlType_SelectedIndexChanged" AutoPostBack="true">
            </asp:DropDownList>
        </td>        
        <td class="ms-formlabel" style="padding-left:5px;">
            <asp:Button ID="btnSearch" runat="server" Text="Generate Report" OnClick="btnSearch_Click" /></td>
        <td class="ms-formlabel">
            <asp:Button ID="btnExportToExcel" runat="server" Visible="false" Text="Export to Excel" OnClick="btnExportToExcel_Click" />
        </td>
    </tr>
    <tr>
        <td colspan="6" style="text-align: center; padding: 6px;">
            <asp:Label ID="lblMessage" runat="server" Text="" ForeColor="green" Font-Bold="true"
                Visible="false"></asp:Label>
            <asp:Label ID="lblErrorMessage" runat="server" Text="" ForeColor="Red" Font-Bold="true"
                Visible="false"></asp:Label>
        </td>
    </tr>
   
    <tr>
        <td colspan="6" style="text-align: center; padding: 6px;">
            <asp:Label ID="lblNoOfRecords" runat="server" Text="" ForeColor="green" Font-Bold="true"
                Visible="false"></asp:Label>
        </td>
    </tr>
    <tr>
        <td colspan="6" style="text-align: center;">
            <asp:GridView ID="grdTMSTotalTenantedSpaces" runat="server" AutoGenerateColumns="false"
                CssClass="tMSReoprtGrd" AllowPaging="true" PageSize="50" AllowSorting="true"
                OnSorting="grdTMSTotalTenantedSpaces_Sorting" OnPageIndexChanging="grdTMSTotalTenantedSpaces_PageIndexChanging"
                EnableViewState="true">
                <Columns>
                    <asp:BoundField DataField="CCName" HeaderText="Name Of Community Club" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="CCName" />
                    <asp:BoundField DataField="CCUnitNumber" HeaderText="Unit No" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="CCUnitNumber" />
                    <asp:BoundField DataField="TenancyRecordNumber" HeaderText="Tenancy Record Number" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="TenancyRecordNumber" />
                    <asp:BoundField DataField="TenantName" HeaderText="Tenant Name" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="TenantName" />
                    <asp:BoundField DataField="TradeCategory" HeaderText="Trade" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="TradeCategory" />
                    <asp:BoundField DataField="FloorArea" HeaderText="Floor Area (SQMT)" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="FloorArea" />
                    <asp:BoundField DataField="RentalDueDate" HeaderText="Rental ($spf)" ControlStyle-BackColor="black"
                        ControlStyle-ForeColor="white" ItemStyle-HorizontalAlign="Center" SortExpression="RentalDueDate" />
                    <asp:BoundField HeaderText="Tenancy/License Details" DataField="AgreementStatus" HtmlEncode="False" />                      
                </Columns>
            </asp:GridView>
        </td>
    </tr>
</table>
<asp:GridView ID="grdExport" runat="server" AutoGenerateColumns="true" CssClass="tMSReoprtGrd" EnableViewState="true"></asp:GridView>