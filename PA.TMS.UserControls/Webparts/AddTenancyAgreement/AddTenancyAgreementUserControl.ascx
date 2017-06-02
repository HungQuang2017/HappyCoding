<%@ Assembly Name="$SharePoint.Project.AssemblyFullName$" %>
<%@ Assembly Name="Microsoft.Web.CommandUI, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> 
<%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> 
<%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Register Tagprefix="asp" Namespace="System.Web.UI" Assembly="System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" %>
<%@ Import Namespace="Microsoft.SharePoint" %> 
<%@ Register Tagprefix="WebPartPages" Namespace="Microsoft.SharePoint.WebPartPages" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="AddTenancyAgreementUserControl.ascx.cs" Inherits="PA.TMS.UserControls.Webparts.AddTenancyAgreement.AddTenancyAgreementUserControl" %>
<link rel="stylesheet" type="text/css" href="../Pages/TMSCore.CSS"/> 

    <script type="text/javascript">

    function allowNumerics(txt, decPos, event) {
        var charCode = (event.which) ? event.which : event.keyCode
        if (charCode == 46) {
            if (txt.value.indexOf(".") < 0)
                return true;
            else
                return false;
        }

        if (txt.value.indexOf(".") > 0) {
            var txtlen = txt.value.length;
            var dotpos = txt.value.indexOf(".");
            if ((txtlen - dotpos) > decPos)
                return false;
        }

        if (charCode > 31 && (charCode < 48 || charCode > 57))
            return false;

        return true;
    }

    function ContractValueCalc(txt, decPos, event) {


        var charCode = (event.which) ? event.which : event.keyCode
        if (charCode == 46) {
            if (txt.value.indexOf(".") < 0)
                return true;
            else
                return false;
        }

        if (txt.value.indexOf(".") > 0) {
            var txtlen = txt.value.length;
            var dotpos = txt.value.indexOf(".");
            if ((txtlen - dotpos) > decPos)
                return false;
        }

        if (charCode > 31 && (charCode < 48 || charCode > 57))
            return false;
        
       }
       
      function fUpdateAppAuthority() { 
        var txt = document.getElementById('<%=txtContractValue.ClientID%>');

        var Elem1 = document.getElementById('<%=lblApprovingAuthority.ClientID%>');



        //var elems = document.getElementsByTagName("select");
        //var matches = [];
        //for (var i=0, m=elems.length; i<m; i++) {
        //    if (elems[i].id && elems[i].id.indexOf("_ddlApprovingAuthority") != -1) {
        //        matches.push(elems[i]);
        //    }
        //}

        if (txt.value == 0.00 || txt.value == "")
        {
            //matches[0].value = 0;
            Elem1.value = "";
        }
        else
        {
            var dSelectedDate = document.getElementById('<%=dtApprovalDate.Controls[0].ClientID%>');

            var dateString = dSelectedDate.value;
            //alert(dateString);
            if (dateString != "")
            {
                var dateParts = dateString.split("/");
                var dateObject = new Date(dateParts[2], dateParts[1] - 1, dateParts[0]); // month is 0-based
                //alert(dateObject.getDate());
                var ruleDateObject = new Date(2016, 06, 01);
                //alert("11 == " + ruleDateObject.getTime());
                //alert("22 == " + dateObject.getTime());
                //alert(txt.value);
                //alert(dateObject);
                //alert(ruleDateObject);
                if (dateObject < ruleDateObject)
                {
                //alert('1');
                        if (txt.value > 0.00 && txt.value <= 100000.00)
                        {
                            //alert('2');
                            //matches[0].selectedIndex = 1;
                            //matches[0].options[1].selected = true;
                            Elem1.value = "Constituency Tender Committee"
                        }
                        
                        if (txt.value > 100000.00 && txt.value <= 1000000.00)
                        {
                            //matches[0].selectedIndex = 2;
                            //matches[0].options[2].selected = true;
                            Elem1.value = "Tender Board A"
                        }
                        
                        if (txt.value > 1000000.00 && txt.value <= 10000000.00)
                        {
                            //matches[0].selectedIndex = 3;
                            Elem1.value = "Tender Board B"
                        }                

                        if (txt.value > 10000000.00)
                        {
                            //matches[0].selectedIndex = 4;
                            Elem1.value = "Tender Board C"
                        }
                }
                else
                {
                        if (txt.value > 0.00 && txt.value <= 250000.00)
                        {
                            Elem1.value = "Constituency Tender Committee"
                            
                        }
                        
                        if (txt.value > 250000.00 && txt.value <= 1000000.00)
                        {
                            Elem1.value = "Tender Board A"
                        }
                        
                        if (txt.value > 1000000.00 && txt.value <= 10000000.00)
                        {
                            Elem1.value = "Tender Board B"
                        }                

                        if (txt.value > 10000000.00)
                        {
                            //matches[0].selectedIndex = 4;
                            Elem1.value = "Tender Board C"
                        }        
                
                }        
                //alert(Elem1.value);
            }        
        }    
        return true;
    }


    function fCheckOption()
    {
        var elems = document.getElementsByTagName("input");
        var matches = [];
        for (var i=0, m=elems.length; i<m; i++) {
            if (elems[i].id && elems[i].id.indexOf("_rdoFixedUtility") != -1) {
                matches.push(elems[i]);
            }
        }
        
        var txtUtilityFees = document.getElementById('<%= txtUtilitiesFees.ClientID %>');
        txtUtilityFees.disabled = true;
        
        if (matches[0].checked)
        {
            txtUtilityFees.disabled = false;
        }
        else
        {
            txtUtilityFees.disabled = true;
            txtUtilityFees.value = "";
        }
    }


    </script>

<p class="ms-standardheader ms-WPTitle">
    <asp:Label ID="lblRenewalMonthlyRent" runat="server" Visible="False"></asp:Label>&nbsp;</p>
<p class="ms-standardheader ms-WPTitle">
    <asp:Label ID="lblPageName" runat="server" Font-Bold="True" Font-Names="Arial" Font-Size="Smaller"
        Width="596px" Visible="False"></asp:Label>&nbsp;</p>
<p class="ms-formvalidation"><asp:Label ID="lblErrorMsg" runat="server"></asp:Label></p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
<tr>
<td style="width:140" class="ms-formlabel">Tenancy Record Number:</td>
<td style="width:400" class="ms-formbody"><asp:Label ID="lblRecordNumber" runat="server"></asp:Label>
    &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;
    <asp:Label ID="lblPrevRecordNumber" runat="server" Visible="False"></asp:Label></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Category:</td>
<td style="width:400" class="ms-formbody"><asp:RadioButton ID="rdoTypeOption1" Checked="true" Text="New" runat="server" GroupName="RecordAgreementType" Enabled="False" /> <asp:RadioButton ID="rdoTypeOption2" Text="Renewal" Enabled="False" runat="server" GroupName="RecordAgreementType" /> <asp:RadioButton ID="rdoTypeOption3" Text="Extension" Enabled="False" runat="server" GroupName="RecordAgreementType" /></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Type of Agreement:</td>
<td style="width:400" class="ms-formbody"><asp:RadioButton ID="rdoAgreementOption1" Text="Tenancy" Checked="true" runat="server" GroupName="AgreementOptions" /> <asp:RadioButton ID="rdoAgreementOption2" Text="Licence" runat="server" GroupName="AgreementOptions" /></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Term of Tenancy/Licence:</td>
<td style="width:400" class="ms-formbody">
<asp:RadioButton ID="rdoTerm1" Text="First" Checked="true" runat="server" GroupName="TermOptions" /> 
<asp:RadioButton ID="rdoTerm2" Text="Second" runat="server" GroupName="TermOptions" />
<asp:RadioButton ID="rdoTerm3" Text="Third" runat="server" GroupName="TermOptions" />
</td>
</tr>
</table>
<br />
<br />
<p class="ms-standardheader ms-WPTitle">Details of Premises</p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
<tr>
<td style="width:140; height: 24px;" class="ms-formlabel">Name of CC:</td>
<td style="width:400; height: 24px;" class="ms-formbody"><asp:DropDownList ID="ddlCCName" CssClass="ms-RadioText" AutoPostBack="True" runat="server" OnSelectedIndexChanged="ddlCCName_SelectedIndexChanged"></asp:DropDownList></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Unit:</td>
<td style="width:400" class="ms-formbody"><asp:RadioButton AutoPostBack="true" OnCheckedChanged="rdoUnitOption1_CheckedChanged" ID="rdoUnitOption1" Text="Single" Checked="true" runat="server" GroupName="Units" /> <asp:RadioButton ID="rdoUnitOption2" OnCheckedChanged="rdoUnitOption2_CheckedChanged" Text="Multiple Units" AutoPostBack="true" runat="server" GroupName="Units" /></td>
</tr>
<tr>
<td style="width:140; vertical-align:text-top;" class="ms-formlabel">Unit Number:</td>
<td style="width:400" class="ms-formbody">
<asp:ListBox ID="lbxUnitNumber" Rows="10" Width="150" runat="server"></asp:ListBox>
<asp:Button CssClass="ms-ButtonHeightWidth" ID="btnGetSQFT" Text="Select Units" runat="server" UseSubmitBehavior="false" OnClick="btnGetSQFT_Click"/>
<p>*To select Multiple Records, press "Shift" key and select.</p>
</td>
</tr>
    <tr>
        <td class="ms-formlabel" style="width: 140px">
            <asp:Label ID="lblselectedUnitnos" runat="server" Text="Selected Unit Nos" Visible="False"
                Width="115px"></asp:Label></td>
        <td class="ms-formbody" style="width: 400px">
            <asp:Label ID="lblselectedunitno" runat="server" Visible="False"></asp:Label></td>
    </tr>
<tr>
<td style="width:140" class="ms-formlabel">Total Floor Area:</td>
<td style="width:400" class="ms-formbody">SQM: <asp:Label ID="lblSQMT" runat="server"></asp:Label><br />
SQFT: <asp:Label ID="lblSQFT" runat="server"></asp:Label></td>
</tr>
</table>
<br />
<br />
<p class="ms-standardheader ms-WPTitle">Approval of Tenancy/Licence</p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
<tr>
<td style="width:140" class="ms-formlabel">Date of Approval:<span class="ms-formvalidation">*</span></td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtApprovalDate" DateOnly="true" LocaleId="2057" runat="server" OnDateChanged="dtApprovalDate_OnDateChanged"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br />
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvApprovalDate" runat="server" ControlToValidate="dtApprovalDate$dtApprovalDateDate" ForeColor="red" ErrorMessage="Select Date of Approval" ValidationGroup="DateError"></asp:RequiredFieldValidator></span>
</td>
</tr>
</table>
<br />
<br />
<p class="ms-standardheader ms-WPTitle">Details of Tenant/Licencee</p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
    <tr>
        <td class="ms-formlabel" style="width: 140px">
            Name of Tenant<span class="ms-formvalidation">*</span>:</td>
        <td class="ms-formbody" style="width: 400px">
            <asp:DropDownList ID="ddlTenantName" CssClass="ms-RadioText" AutoPostBack="True" runat="server" OnSelectedIndexChanged="ddlTenantName_SelectedIndexChanged" Width="154px">
            </asp:DropDownList>
            <asp:RequiredFieldValidator ID="rfvTenantName" runat="server" ControlToValidate="ddlTenantName" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></td>
    </tr>
<tr>
<td style="width:140" class="ms-formlabel">Trading Name:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtTradingName" CssClass="ms-long" runat="server"></asp:Textbox></td>
</tr>
    <tr>
        <td class="ms-formlabel" style="width: 140px">
            Type of Company</td>
        <td class="ms-formbody" style="width: 400px">
            <asp:TextBox ID="txtCompanyType" runat="server" CssClass="ms-long"></asp:TextBox></td>
    </tr>
<tr>
<td style="width:140; height: 25px;" class="ms-formlabel">ROC/UEN Number<span class="ms-formvalidation">*</span>:</td>
<td style="width:400; height: 25px;" class="ms-formbody">
<asp:Textbox ID="txtROCNumber" CssClass="ms-long" runat="server" ReadOnly="True"></asp:Textbox>
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvROCNumber" runat="server" ControlToValidate="txtROCNumber" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">ID Number of Sole-Proprietor:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtFIN"  CssClass="ms-long" runat="server"></asp:Textbox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Name of Person In-Charge:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtPersonInCharge" CssClass="ms-long" runat="server"></asp:Textbox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Registered Address:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtRegisteredAdd" CssClass="ms-long" runat="server" ReadOnly="True"></asp:Textbox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Office Number:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtOffNumber" CssClass="ms-long" runat="server"></asp:Textbox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Hand Phone Number:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtPhoneNumber" CssClass="ms-long" runat="server"></asp:Textbox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Email Address:</td>
<td style="width:400" class="ms-formbody"><asp:Textbox ID="txtEmail" CssClass="ms-long" runat="server"></asp:Textbox></td>
</tr>
</table>
<br />
<br />
<p class="ms-standardheader ms-WPTitle">Details of Agreement</p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
<tr>
<td style="width:140" class="ms-formlabel">Trade Category<span class="ms-formvalidation">*</span>:</td>
<td style="width:400" class="ms-formbody">
<asp:DropDownList ID="ddlTradeCat" AutoPostBack="true" CssClass="ms-RadioText" OnSelectedIndexChanged="ddlTradeCat_SelectedIndexChanged" runat="server"></asp:DropDownList>
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvTradeCat" runat="server" ControlToValidate="ddlTradeCat" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured" InitialValue="Select Trade Category"></asp:RequiredFieldValidator></span>
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Type of Trade<span class="ms-formvalidation">*</span>:</td>
<td style="width:400" class="ms-formbody">
<asp:DropDownList ID="ddlTradeType" CssClass="ms-RadioText" runat="server"></asp:DropDownList>
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvTradeType" runat="server" ControlToValidate="ddlTradeType" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured" InitialValue="Select Trade Type"></asp:RequiredFieldValidator></span>
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Halal Certification<span class="ms-formvalidation">*</span>:</td>
<td style="width:400" class="ms-formbody">
<asp:RadioButton ID="rdoHalalCertYes" Text="Yes" runat="server" GroupName="HalalCert" /> <asp:RadioButton ID="rdoHalalCertNo" Checked="true" Text="No" runat="server" GroupName="HalalCert" />
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Space Classification<span class="ms-formvalidation">*</span>:</td>
<td style="width:400" class="ms-formbody">
<asp:RadioButton ID="rdoSpace1" Text="Commercial" Checked="true" runat="server" GroupName="SpaceClass" /> 
<asp:RadioButton ID="rdoSpace2" Text="C & CI" runat="server" GroupName="SpaceClass" />
<asp:RadioButton ID="rdoSpace3" Text="Utility" runat="server" GroupName="SpaceClass" />
<p>Community & Civic Institutions (C&CI):Government Agencies, Childcare and Social Service Centres<br />
Utility: Postal Office, Base Stations</p>
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">1st Term Tenure<span class="ms-formvalidation">*</span>:</td>
<td style="width:400" class="ms-formbody">
<asp:Textbox ID="txtTenureYear" Width="90" CssClass="ms-long" runat="server"></asp:Textbox> Year 
<asp:Textbox ID="txtTenureMonth" Width="90" CssClass="ms-long" runat="server"></asp:Textbox> Month
<asp:Textbox ID="txtTenureDay" Width="90" CssClass="ms-long" runat="server"></asp:Textbox> Day
<asp:CustomValidator ID="valTenure" runat="server" Display="Dynamic" OnServerValidate="TenureValidation" ErrorMessage="Tenure Details cannot be empty." ForeColor="Red" />
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">1st Renewal Tenure<span class="ms-formvalidation">*</span>:</td>
<td style="width:400" class="ms-formbody">
<asp:Textbox ID="txtRenewalYear" Width="90" CssClass="ms-long" runat="server"></asp:Textbox> Year 
<asp:Textbox ID="txtRenewalMonth" Width="90" CssClass="ms-long" runat="server"></asp:Textbox> Month
<asp:Textbox ID="txtRenewalDay" Width="90" CssClass="ms-long" runat="server"></asp:Textbox> Day
<asp:CustomValidator ID="valRenewal" runat="server" Display="Dynamic" OnServerValidate="RenewalValidation" ErrorMessage="Renewal Details cannot be empty." ForeColor="Red" />
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">2nd Renewal Tenure:</td>
<td style="width:400" class="ms-formbody">
<asp:Textbox ID="txtRenewalYear2" Width="90" CssClass="ms-long" runat="server" Text="0"></asp:Textbox> Year 
<asp:Textbox ID="txtRenewalMonth2" Width="90" CssClass="ms-long" runat="server" Text="0"></asp:Textbox> Month
<asp:Textbox ID="txtRenewalDay2" Width="90" CssClass="ms-long" runat="server" Text="0"></asp:Textbox> Day
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Stamp Duty Filing Date:</td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtStampDutyDate" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/>
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Fitting Out Start Date:</td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtFittingFrom" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/>
</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Fitting Out End Date:</td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtFittingTo" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/>
</td>
</tr>
    <tr>
        <td class="ms-formlabel" style="width: 140px">
            Payment Option:</td>
        <td class="ms-formbody" style="width: 400px">
            <asp:RadioButton ID="rdopaymentoption1" runat="server" Checked="True" GroupName="vgPaymentOption"
                Text="Monthly" />
            <asp:RadioButton ID="rdopaymentoption2" runat="server" GroupName="vgPaymentOption"
                Text="LumpSum" /></td>
    </tr>
</table>
<br />
<br />

<p class="ms-standardheader ms-WPTitle">Monthly Rental/Fees</p>
<p>For tenancy with staggered rental/fees, add new row for each period.</p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
    <tr>
        <td style="width: 140px;" class="ms-formlabel">
            Type:
        </td>
        <td style="width: 400px;" class="ms-formbody">
            <asp:RadioButton ID="rdbTenure" Text="Tenure" Checked="true" runat="server" GroupName="TenancyType" />
            <asp:RadioButton ID="rdbRenewal" Text="Renewal" runat="server" GroupName="TenancyType" Enabled="False" />
        </td>
    </tr>
    <tr>
        <td style="width: 140px;" class="ms-formlabel">
            Tenancy/Licence Start Date<span class="ms-formvalidation">*</span>:
        </td>
        <td style="width: 400px;" class="ms-formbody">
            <SharePoint:DateTimeControl ID="dtcTLStartDate" DateOnly="true" LocaleId="2057" runat="server">
            </SharePoint:DateTimeControl>
            Date Format: DD/MM/YYYY<br />
            <span class="ms-formdescription">&nbsp;</span></td>
    </tr>
    <tr>
        <td style="width: 140px;" class="ms-formlabel">
            Tenancy/Licence End Date<span class="ms-formvalidation">*</span>:
        </td>
        <td style="width: 400px;" class="ms-formbody">
            <SharePoint:DateTimeControl ID="dtcTLEndDate" DateOnly="true" LocaleId="2057" runat="server">
            </SharePoint:DateTimeControl>
            Date Format: DD/MM/YYYY<br />
            <span class="ms-formdescription">&nbsp;</span></td>
    </tr>
    <tr>
        <td style="width: 140px;" class="ms-formlabel">
            Monthly Rent<span class="ms-formvalidation">*</span>:
        </td>
        <td style="width: 400px;" class="ms-formbody">
            $
            <asp:TextBox ID="txtTLMonthlyRent" runat="server" CssClass="ms-input" MaxLength="255"
                onkeypress="return allowNumerics(this, 2, event);" Width="155px" OnTextChanged="txtTLMonthlyRent_TextChanged"
                AutoPostBack="true"></asp:TextBox><br />
            <span class="ms-formdescription">&nbsp;</span></td>
    </tr>
    <tr>
        <td style="width: 140px;" class="ms-formlabel">
            Rent per Square Foot<span class="ms-formvalidation">*</span>:
        </td>
        <td style="width: 400px;" class="ms-formbody">
            $
            <asp:TextBox ID="txtTLRentPerSF" runat="server" CssClass="ms-input" MaxLength="255"
                Width="155px" onkeypress="return allowNumerics(this, 2, event);"></asp:TextBox><br />
            <span class="ms-formdescription">&nbsp;</span></td>
    </tr>
    <tr>
        <td style="width: 140px;" class="ms-formlabel">
        </td>
        <td style="width: 400px;" class="ms-formbody">
            <asp:HiddenField ID="hidIQTLIDValue" runat="server" />
            <asp:Button ID="btnMonthlyRent" Text="Add" runat="server" CssClass="ms-ButtonHeightWidth"
                ValidationGroup="MonthlyRent" OnClick="btnMonthlyRent_Click" />
            <p class="ms-formvalidation">
                <asp:Label ID="lblMonthlyRentMsg" runat="server"></asp:Label></p>
        </td>
    </tr>
</table>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
    <tr>
        <td width="100%">
            <asp:GridView ID="grvMonthlyRent" runat="server" AutoGenerateColumns="false" CssClass="htnl_tbl"
                Width="100%" OnRowCommand="grvMonthlyRent_RowCommand">
                <Columns>
                    <asp:BoundField DataField="ID" HeaderText="S.No" ItemStyle-VerticalAlign="Middle"
                        ItemStyle-HorizontalAlign="Center" />
                    <asp:BoundField DataField="RentType" HeaderText="Type" />
                    <asp:BoundField DataField="StartDate" HeaderText="Start Date" />
                    <asp:BoundField DataField="EndDate" HeaderText="End Date" />
                    <asp:BoundField DataField="MonthlyRent" HeaderText="Monthly Rent" DataFormatString="${0:d}"
                        ItemStyle-VerticalAlign="Middle" ItemStyle-HorizontalAlign="Center" />
                    <asp:BoundField DataField="RentPerSQF" HeaderText="Rent Per Sq.F" DataFormatString="${0:d}"
                        ItemStyle-VerticalAlign="Middle" ItemStyle-HorizontalAlign="Center" />
                    <asp:TemplateField HeaderText="Action">
                        <ItemTemplate>
                            <asp:ImageButton ID="imgbtnEdit" runat="server" CommandArgument='<%# Eval("ID") %>'
                                CommandName="EditTL" ImageUrl="/_layouts/images/EDIT.GIF" />
                            <asp:ImageButton ID="imgbtnDelete" runat="server" CommandArgument='<%# Eval("ID") %>'
                                CommandName="DeleteTL" ImageUrl="/_layouts/images/DELETE.GIF" OnClientClick="return confirm('Are you sure to delete this item?');" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </td>
    </tr>
    <tr>
        <td>
            First Billing Amount: $<asp:Label ID="lblIQFirsrBA" runat="server"></asp:Label>
        </td>
    </tr>
    <tr>
        <td>
            Last Billing Amount: $<asp:Label ID="lblIQLastBA" runat="server"></asp:Label>
        </td>
    </tr>
</table>
<asp:GridView ID="grvTenantDetails" runat="server"  AutoGenerateColumns="False"
    ForeColor="#333333" Visible="false"
    Width="100%" 
    Style="text-align: left" OnRowDeleting="grvTenantDetails_RowDeleting">
    <Columns>
         <asp:TemplateField>
            <ItemTemplate>
              <SharePoint:DateTimeControl ID="TenancyStartDate" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/>
              <span class="ms-formdescription">&nbsp;</ItemTemplate>
            <HeaderTemplate>
                Tenancy/Licence Start Date<span class="ms-formvalidation">*</span>
            </HeaderTemplate>
        </asp:TemplateField>
        
        <asp:TemplateField>
            <ItemTemplate>
               <SharePoint:DateTimeControl ID="TenancyEndDate" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/>
              <span class="ms-formdescription">&nbsp;</ItemTemplate>                            
            <HeaderTemplate>
                Tenancy/Licence End Date<span class="ms-formvalidation">*</span>
            </HeaderTemplate>
        </asp:TemplateField>

        <asp:TemplateField>
            <ItemTemplate>
                $ <asp:TextBox ID="txtCompliance3" runat="server" CssClass="ms-input" MaxLength="255" Width="155px" onkeypress="return allowNumerics(this, 2, event);" AutoPostBack="true" OnTextChanged="txtCompliance3_TextChanged"></asp:TextBox><br />
              <span class="ms-formdescription">&nbsp;</ItemTemplate>                            
            <HeaderTemplate>
                Monthly Rent<span class="ms-formvalidation">*</span>
            </HeaderTemplate>
        </asp:TemplateField>
          <asp:TemplateField>
            <ItemTemplate>
                $ <asp:TextBox ID="txtCompliance4" runat="server" CssClass="ms-input" MaxLength="255" Width="155px" onkeypress="return allowNumerics(this, 2, event);"></asp:TextBox><br />
              <span class="ms-formdescription">&nbsp;</ItemTemplate>                            
            <HeaderTemplate>
                Rent per Square Foot<span class="ms-formvalidation">*</span>
            </HeaderTemplate>
        </asp:TemplateField>

        <asp:TemplateField Visible="False">
            <ItemTemplate>
                <asp:Label ID="lblLicenseDetailID" runat="server" Text='0' />
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField Visible="False">
            <ItemTemplate>
                <asp:Label ID="lblFirstRent" runat="server" Text='0.00' />
            </ItemTemplate>
        </asp:TemplateField>
        <asp:TemplateField Visible="False">
            <ItemTemplate>
                <asp:Label ID="lblLastRent" runat="server" Text='0.00' />
            </ItemTemplate>
        </asp:TemplateField>                
        
        <asp:CommandField ShowDeleteButton="True" DeleteText="Remove Details" >
        <ControlStyle ForeColor="Blue" />
        <ItemStyle VerticalAlign="Middle" />
        </asp:CommandField>
        <asp:TemplateField>
            <HeaderStyle HorizontalAlign="Right" />
            <HeaderTemplate>
                <asp:Button ID="ButtonAdd" runat="server" Text="Add New Row" OnClick="ButtonAdd_Click" />
            </HeaderTemplate>
        </asp:TemplateField>
        
    </Columns>
</asp:GridView>
<br />
<asp:Label ID="lblFirstRentNotes" runat="server"></asp:Label>
<asp:Label ID="lblLastRentNotes" runat="server"></asp:Label>
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;&nbsp;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;<strong>
    <asp:Label ID="lbltempbalancedaysFirst" runat="server" Visible="False"></asp:Label>&nbsp;
    <asp:Label ID="lbltempbalancedaysLast" runat="server" Visible="False"></asp:Label>&nbsp;<br />
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;
        <asp:Button ID="UpdateValues" runat="server" OnClick="UpdateValues_Click" Text="Refresh First&Last Partial Deposits" />&nbsp;
        <asp:Label ID="lbltotaltenuremonths" runat="server" Visible="False" Font-Bold="False"></asp:Label>
    <asp:Label ID="lbltotaltenurevalue" runat="server" Visible="False" Font-Bold="False"></asp:Label>
    <asp:Label ID="PrevTANo" runat="server" Font-Bold="False" Visible="False"></asp:Label>
    <asp:Label ID="Prevtenurevalue" runat="server" Font-Bold="False" Visible="False"></asp:Label><br />
    <asp:Label ID="lblrenewmessage" runat="server" ForeColor="Red"></asp:Label><br />
</strong><table width="900" class="ms-formtable" style="margin-top: 8px;" border="0">
    <tr>
        <td class="ms-formlabel" style="width: 4759px; height: 65px">
            Total Contract Value<span class="ms-formvalidation">*</span>:</td>
        <td class="ms-formbody" style="width: 25000px">
            $ <asp:Textbox ID="txtContractValue" CssClass="ms-long" onkeypress="return ContractValueCalc(this, 2, event);" onblur="return fUpdateAppAuthority();" runat="server" OnTextChanged="txtContractValue_TextChanged" Enabled="False"></asp:Textbox>

<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvContractValue" runat="server" ControlToValidate="txtContractValue" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>
    <br />
        </td>
    </tr>
    <tr>
        <td class="ms-formlabel" style="width: 4759px; height: 65px">
            Approving Authority<span class="ms-formvalidation">*</span>:</td>
        <td class="ms-formbody" style="width: 25000px">
<asp:TextBox ID="lblApprovingAuthority" Enabled="False" CssClass="ms-long" runat="server"></asp:TextBox>
        </td>
    </tr>
<tr>
<td style="width:4759px; height: 65px;" class="ms-formlabel">Security Deposit<span class="ms-formvalidation">*</span>:</td>
<td style="width:25000px;" class="ms-formbody">$ <asp:Textbox ID="txtSecurityAmt" Width="200" CssClass="ms-long" runat="server"></asp:Textbox>&#160;&#160;
<asp:RadioButton ID="chkCash" Checked="true" Text="Cash" runat="server" GroupName="SecurityDep" />&#160;&#160;
<asp:RadioButton ID="chkBankGurantee" Text="Bank Gurantee" GroupName="SecurityDep" runat="server" />&nbsp;<br />

<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvSecurityAmt" runat="server" ControlToValidate="txtSecurityAmt" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>
    <br />
        <asp:Label ID="lblFirstMonthlyRent1" runat="server" Visible="False"></asp:Label><asp:Label ID="lblLastMonthlyRent1"
            runat="server" Visible="False"></asp:Label></td>
</tr>
<tr>
<td style="width:4759px" class="ms-formlabel">Utilities Deposit<span class="ms-formvalidation">*</span>:</td>
<td style="width:2100px" class="ms-formbody">$ <asp:Textbox ID="txtUtilitiesDeposit" Width="200" CssClass="ms-long" runat="server"></asp:Textbox><br />
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvUtilitiesDeposit" runat="server" ControlToValidate="txtUtilitiesDeposit" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>
    <br />
        <asp:Label ID="lblFirstMonthlyRent2" runat="server" Visible="False"></asp:Label><asp:Label
            ID="lblLastMonthlyRent2" runat="server" Visible="False"></asp:Label></td>
</tr>
<tr>
<td style="width:4759px" class="ms-formlabel">Fitting Out Deposit<span class="ms-formvalidation">*</span>:</td>
<td style="width:2100px" class="ms-formbody">$ <asp:Textbox ID="txtFittingDeposit" Width="200" CssClass="ms-long" runat="server"></asp:Textbox><br />
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvFittingDeposit" runat="server" ControlToValidate="txtFittingDeposit" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>
    <br />
        <asp:Label ID="lblFirstMonthlyRent3" runat="server" Visible="False"></asp:Label><asp:Label
            ID="lblLastMonthlyRent3" runat="server" Visible="False"></asp:Label></td>
</tr>
<tr>
<td style="width:4759px" class="ms-formlabel">Service & Conservancy Charges<span class="ms-formvalidation">*</span>:</td>
<td style="width:2100px" class="ms-formbody">$ <asp:Textbox ID="txtServiceChgs" Width="200" CssClass="ms-long" runat="server"></asp:Textbox><br />
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvServiceChgs" runat="server" ControlToValidate="txtServiceChgs" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>&nbsp;<br />
        <asp:Label ID="lblFirstMonthlyRent4" runat="server"></asp:Label><asp:Label ID="lblLastMonthlyRent4"
            runat="server"></asp:Label></td>
</tr>
<tr>
<td style="width:4759px" class="ms-formlabel">Utilities Fees:</td>
<td style="width:2100px" class="ms-formbody">
<asp:RadioButton ID="rdoFixedUtility" Text="Fixed" runat="server" AutoPostBack="true" onclick="return fCheckOption();" GroupName="UtilityFees" /> <asp:RadioButton ID="rdoVarUtility" Text="Variable" Checked="true" runat="server" AutoPostBack="true" onclick="return fCheckOption();" GroupName="UtilityFees" OnCheckedChanged="rdoVarUtility_CheckedChanged" />
    <asp:RadioButton ID="rdodirectUtility" runat="server" GroupName="UtilityFees" Text="Direct" AutoPostBack="True" /><br />
$ <asp:Textbox ID="txtUtilitiesFees" Width="200" Enabled="false" onkeypress="return allowNumerics(this, 2, event);" Text="0" CssClass="ms-long" runat="server"></asp:Textbox>
    <br />
        <asp:Label ID="lblFirstMonthlyRent5" runat="server"></asp:Label><asp:Label
            ID="lblLastMonthlyRent5" runat="server"></asp:Label></td>

</tr>
    <tr>
        <td class="ms-formlabel" style="width: 4759px">
            SignageFees:</td>
        <td class="ms-formbody" style="width: 2100px">
            $<asp:TextBox ID="txtSignageFees" runat="server"></asp:TextBox><br />
            <asp:Label ID="lblFirstMonthlyRent6" runat="server"></asp:Label>
            <asp:Label ID="lblLastMonthlyRent6" runat="server"></asp:Label></td>
    </tr>
    <tr>
        <td class="ms-formlabel" style="width: 4759px">
            Other Fees1($):</td>
        <td class="ms-formbody" style="width: 2100px">
            <asp:DropDownList ID="ddlOtherFees1" CssClass="ms-RadioText" runat="server" OnSelectedIndexChanged="ddlOtherFees_SelectedIndexChanged" Width="154px">
            </asp:DropDownList><asp:TextBox ID="txtOtherFeesValue1" runat="server"></asp:TextBox><br />
        <asp:Label ID="lblFirstMonthlyRent7" runat="server"></asp:Label><asp:Label ID="lblLastMonthlyRent7"
            runat="server"></asp:Label></td>
    </tr>
<tr>
<td style="width:4759px" class="ms-formlabel">
    </td>
<td style="width:2100px" class="ms-formbody">
    &nbsp;<asp:DropDownList ID="ddlOtherFees2" runat="server" CssClass="ms-RadioText"
        OnSelectedIndexChanged="ddlOtherFees_SelectedIndexChanged" Width="154px" Visible="False">
    </asp:DropDownList>
    <asp:TextBox ID="txtOtherFeesValue2" runat="server" Visible="False"></asp:TextBox></td>
</tr>
<tr>
<td style="width:4759px" class="ms-formlabel">Rental/Fees Due Date<span class="ms-formvalidation">*</span>:</td>
<td style="width:2100px" class="ms-formbody">
<asp:DropDownList ID="ddlRentalDueDate" CssClass="ms-RadioText" runat="server">
    <asp:ListItem>Select Due Date</asp:ListItem>
    <asp:ListItem Selected="True">1</asp:ListItem>
    <asp:ListItem>2</asp:ListItem>
    <asp:ListItem>3</asp:ListItem>
    <asp:ListItem>4</asp:ListItem>
    <asp:ListItem>5</asp:ListItem>
    <asp:ListItem>6</asp:ListItem>
    <asp:ListItem>7</asp:ListItem>
    <asp:ListItem>8</asp:ListItem>
    <asp:ListItem>9</asp:ListItem>
    <asp:ListItem>10</asp:ListItem>
    <asp:ListItem>11</asp:ListItem>
    <asp:ListItem>12</asp:ListItem>
    <asp:ListItem>13</asp:ListItem>
    <asp:ListItem>14</asp:ListItem>
    <asp:ListItem>15</asp:ListItem>
    <asp:ListItem>16</asp:ListItem>
    <asp:ListItem>17</asp:ListItem>
    <asp:ListItem>18</asp:ListItem>
    <asp:ListItem>19</asp:ListItem>
    <asp:ListItem>20</asp:ListItem>
    <asp:ListItem>21</asp:ListItem>
    <asp:ListItem>22</asp:ListItem>
    <asp:ListItem>23</asp:ListItem>
    <asp:ListItem>24</asp:ListItem>
    <asp:ListItem>25</asp:ListItem>
    <asp:ListItem>26</asp:ListItem>
    <asp:ListItem>27</asp:ListItem>
    <asp:ListItem>28</asp:ListItem>
    <asp:ListItem>29</asp:ListItem>
    <asp:ListItem>30</asp:ListItem>
    <asp:ListItem>31</asp:ListItem>    
</asp:DropDownList><br />
Day in a month. <br/>
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvRentalDueDate" runat="server" ControlToValidate="ddlRentalDueDate" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured" InitialValue="Select Due Date"></asp:RequiredFieldValidator></span>
</td>
</tr>
    <tr>
        <td class="ms-formlabel" style="width: 4759px">
            Late Payment Interest Rate (%)<span class="ms-formvalidation">*</span>:</td>
        <td class="ms-formbody" style="width: 2100px">
            <asp:RadioButton ID="rdofixedlatepayment" runat="server" GroupName="glatepaymentintrestrate"
                Text="Fixed" AutoPostBack="True" OnCheckedChanged="rdofixedlatepayment_CheckedChanged" />
            <asp:RadioButton ID="rdovariablelatepayment" runat="server" GroupName="glatepaymentintrestrate"
                Text="Prevaling" AutoPostBack="True" OnCheckedChanged="rdovariablelatepayment_CheckedChanged" /><br />
<asp:Textbox ID="txtLatePayment" Width="200" CssClass="ms-long" runat="server">0</asp:Textbox>%<br />
            <asp:RequiredFieldValidator ID="rfvLatePayment" runat="server" ControlToValidate="txtLatePayment" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></td>
    </tr>
<tr>
<td style="width:4759px" class="ms-formlabel">Grace Period (in days)<span class="ms-formvalidation">*</span>:</td>
<td style="width:2100px" class="ms-formbody">
<asp:DropDownList ID="ddlGracePeriod" CssClass="ms-RadioText" runat="server">
    <asp:ListItem>Select Grace Period</asp:ListItem>
    <asp:ListItem Selected="True">0</asp:ListItem>
    <asp:ListItem>1</asp:ListItem>
    <asp:ListItem>2</asp:ListItem>
    <asp:ListItem>3</asp:ListItem>
    <asp:ListItem>4</asp:ListItem>
    <asp:ListItem>5</asp:ListItem>
    <asp:ListItem>6</asp:ListItem>
    <asp:ListItem>7</asp:ListItem>
    <asp:ListItem>8</asp:ListItem>
    <asp:ListItem>9</asp:ListItem>
    <asp:ListItem>10</asp:ListItem>
    <asp:ListItem>11</asp:ListItem>
    <asp:ListItem>12</asp:ListItem>
    <asp:ListItem>13</asp:ListItem>
    <asp:ListItem>14</asp:ListItem>
    <asp:ListItem>15</asp:ListItem>
    <asp:ListItem>16</asp:ListItem>
    <asp:ListItem>17</asp:ListItem>
    <asp:ListItem>18</asp:ListItem>
    <asp:ListItem>19</asp:ListItem>
    <asp:ListItem>20</asp:ListItem>
    <asp:ListItem>21</asp:ListItem>
    <asp:ListItem>22</asp:ListItem>
    <asp:ListItem>23</asp:ListItem>
    <asp:ListItem>24</asp:ListItem>
    <asp:ListItem>25</asp:ListItem>
    <asp:ListItem>26</asp:ListItem>
    <asp:ListItem>27</asp:ListItem>
    <asp:ListItem>28</asp:ListItem>
    <asp:ListItem>29</asp:ListItem>
    <asp:ListItem>30</asp:ListItem>
</asp:DropDownList><br />
Grace period specified in Tenancy Agreement, if any.<br />
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvGracePeriod" runat="server" ControlToValidate="ddlGracePeriod" ErrorMessage="Required field cannot be left blank." ForeColor="Red" Display="Dynamic" ValidationGroup="ErrorOccured" InitialValue="Select Grace Period"></asp:RequiredFieldValidator></span>
</td>
</tr>
</table>
<br />
<br />
<p class="ms-standardheader ms-WPTitle">Other Details</p>
<table width="600" class="ms-formtable" style="margin-top: 8px;" border="0">
<tr>
<td style="width:140" class="ms-formlabel">Suspension Start Date:</td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtSuspensionFrom" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br />
For temporary suspension of tenancy due to upgrading</td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Suspension End Date:</td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtSuspensionTo" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Early Termination Date:</td>
<td style="width:400" class="ms-formbody">
<SharePoint:DateTimeControl ID="dtEarlyTerminationDate" DateOnly="true" LocaleId="2057" runat="server"></SharePoint:DateTimeControl>Date Format: DD/MM/YYYY<br/></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Reason for Early Termination:</td>
<td style="width:400" class="ms-formbody"><asp:TextBox ID="txtReason" CssClass="ms-long" runat="server" TextMode="MultiLine" Rows="10" Columns="6"></asp:TextBox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Remarks:</td>
<td style="width:400" class="ms-formbody"><asp:TextBox ID="txtRemarks" CssClass="ms-long" runat="server" TextMode="MultiLine" Rows="10" Columns="6"></asp:TextBox></td>
</tr>
<tr>
<td style="width:140" class="ms-formlabel">Agreement Status:<span class="ms-formvalidation">*</span></td>
<td style="width:400" class="ms-formbody">
<asp:DropDownList ID="drpAgreementStatus" CssClass="ms-RadioText" runat="server" CausesValidation="true" ></asp:DropDownList>
<span class="ms-formdescription"><asp:RequiredFieldValidator ID="rfvAgreementStatus" runat="server"  InitialValue="Select Agreement Status" ControlToValidate="drpAgreementStatus" ForeColor="red" ErrorMessage="Select Agreement Status" ValidationGroup="ErrorOccured"></asp:RequiredFieldValidator></span>
    <br />
<asp:Label ID="lblTest" runat="server" ForeColor="Red"></asp:Label>
</td>
</tr>
</table>
<br />
<asp:Button CssClass="ms-ButtonHeightWidth" ID="btnSave" Text="Submit" runat="server" OnClick="btnSave_Click"/><asp:Button ID="btnCancel" CssClass="ms-ButtonHeightWidth" Text="Cancel" runat="server" OnClick="btnCancel_Click" />
<asp:Button CssClass="ms-ButtonHeightWidth" ID="btnDraft" Text="Save As Draft" runat="server" OnClick="btnDraft_Click"/>