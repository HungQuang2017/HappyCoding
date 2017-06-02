using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.IO;
using System.Text.RegularExpressions;
using System.Web.UI.HtmlControls;
using Microsoft.SharePoint;
using Microsoft.SharePoint.WebControls;
using System.Drawing;
using System.Globalization;
using System.Text;

namespace PA.TMS.UserControls.Webparts.AddTenancyAgreement
{
    public partial class AddTenancyAgreementUserControl : UserControl
    {
        SPSite site = SPContext.Current.Site;
        string strCommunityClubListName = "CommunityClub";
        string strAgreementListName = "TenancyAgreement";
        string strUnitInformationList = "UnitInformation";
        string strTenantMasterListName = "TenantMasterList"; //added by sk declare list
        string strGeneralSettings = "GeneralSettings"; // ph2 dev 

        string strAgreementListNameDraft = "TenancyAgreementDraft"; //ph2




        bool bEdit = false;
        string flagmode = "";
        string OthersGrp = "Others";
        string BDGroup = "Business Development";
        string strTestTenantList = "AgreementLicense";
        string strTestTenantListDraft = "AgreementLicenseDraft"; //ph2
        string strTradeCategoryList = "TradeCategory";

        string FormType = "Tenancy Agreement";
        string EditUrl = "/Pages/AddAgreement.aspx?edit=true";
        string ViewUrl = "/Pages/ViewAgreement.aspx";

        int iRecord = 0;
        int iCCID = 0;

        //ph2 

        string mRecord = "";  //mode
        int piRecord = 0;   //prev id


        string sTenancyRecordType = "";
        string sAgreementCategory = "";

        int aintNoOfDays = 0;
        int aintNoOfMonths = 0;
        int aintNoOfYears = 0;
        int preserverowno = 0;
        //	double RenewalMonthlyRent;

        public const string strErrorTitle = "TenancyAgreement";




        protected void Page_Load(object sender, EventArgs e)
        {
            //Page.MaintainScrollPositionOnPostBack = true;

            if (!String.IsNullOrEmpty(Request.QueryString["edit"]))
            {
                bEdit = Convert.ToBoolean(Request.QueryString["edit"]);
            }

            //ph2 
            if (!string.IsNullOrEmpty(Request.QueryString["drID"]))
            {
                mRecord = "Draft";
            }

            if (mRecord == "Draft")
            {
                iRecord = Convert.ToInt32(Request.QueryString["drID"]);
                piRecord = Convert.ToInt32(Request.QueryString["drID"]);
            }
            else
            {
                iRecord = Convert.ToInt32(Request.QueryString["rID"]);
            }

            //end



            if (!Page.IsPostBack)
            {
                LoadAgreementForm();
                if (!bEdit)
                {
                    lblPageName.Text = "Add Agreement (Tenancy)";
                    FirstGridViewRow();
                }
                else
                {
                    if (mRecord == "Draft")
                    {
                        iRecord = Convert.ToInt32(Request.QueryString["drID"]);
                    }
                    else
                    {
                        iRecord = Convert.ToInt32(Request.QueryString["rID"]);
                    }

                    //bindLicenseGrid(iRecord);
                    BindLeaseAgreementLicense("0");

                }
            }


            if (Page.IsPostBack)
            {
                this.Page.ClientScript.RegisterStartupScript(this.GetType(), "AlertMsg", "fUpdateAppAuthority();", true);
            }
        }

        #region Monthly Rent Calulations

        protected void btnMonthlyRent_Click(object sender, EventArgs e)
        {
            try
            {
                Button btnAdd = (Button)sender;
                DataTable dt = null;
                HiddenField hidtlidval = null;
                DateTimeControl dtcSD = null;
                DateTimeControl dtcED = null;
                TextBox txtR = null;
                TextBox txtRSQFT = null;
                RadioButton rdbT = null;
                RadioButton rdbR = null;
                Label lblmsg = null;
                lblErrorMsg.Text = string.Empty;

                if (ViewState["dtIQMonthlyRent"] != null)
                {
                    dt = (DataTable)ViewState["dtIQMonthlyRent"];
                    if (dt == null)
                        initiateMonthlyRentDT(dt);
                }
                else
                {
                    dt = initiateMonthlyRentDT(dt);
                    ViewState["dtIQMonthlyRent"] = dt;
                }
                dt = (DataTable)ViewState["dtIQMonthlyRent"];
                rdbT = rdbTenure;
                rdbR = rdbRenewal;
                dtcSD = dtcTLStartDate;
                dtcED = dtcTLEndDate;
                txtR = txtTLMonthlyRent;
                txtRSQFT = txtTLRentPerSF;
                hidtlidval = hidIQTLIDValue;
                lblmsg = lblMonthlyRentMsg;

                hideMessage(lblmsg);
                if (btnAdd.Text.ToLower() == "add")
                {
                    if (!checkForTRDateValidation("0"))
                    {
                        hidtlidval.Value = "";

                        DataRow dr = dt.NewRow();
                        dr["ID"] = (dt.Rows.Count + 1).ToString();
                        if (rdbT.Checked)
                            dr["RentType"] = "Tenure";
                        else if (rdbR.Checked)
                            dr["RentType"] = "Renewal";
                        dr["StartDate"] = dtcSD.SelectedDate.ToString("dd/MM/yyyy");
                        dr["EndDate"] = dtcED.SelectedDate.ToString("dd/MM/yyyy");
                        dr["MonthlyRent"] = txtR.Text.Trim();
                        dr["RentPerSQF"] = txtRSQFT.Text.Trim();
                        dt.Rows.Add(dr);

                        BindMonthlyRentGrid(dt, "0", false);

                        ViewState["dtIQMonthlyRent"] = dt;
                        clearMonthlyRentControls("0");


                        CalculateFirstLastBillingAmount(dt, "0");
                        CalculateEstimatedValue(dt, "0");

                        displayErrorMessage(lblmsg, "Added successfully", MessageScope.Success);
                    }
                }
                else if (btnAdd.Text.ToLower() == "save")
                {
                    if (!checkForTRDateValidation("0"))
                    {
                        hidtlidval = hidIQTLIDValue;
                        dt = (DataTable)ViewState["dtIQMonthlyRent"];


                        if (!string.IsNullOrEmpty(hidtlidval.Value))
                        {
                            DataRow[] dr = dt.Select(string.Format("ID = '{0}'", hidtlidval.Value));
                            if (dr.Length > 0)
                            {
                                dr[0]["StartDate"] = dtcSD.SelectedDate.ToString("dd/MM/yyyy");
                                dr[0]["EndDate"] = dtcED.SelectedDate.ToString("dd/MM/yyyy");
                                dr[0]["MonthlyRent"] = txtR.Text.Trim();
                                dr[0]["RentPerSQF"] = txtRSQFT.Text.Trim();
                                dt.AcceptChanges();
                            }

                            BindMonthlyRentGrid(dt, "0", false);
                            CalculateFirstLastBillingAmount(dt, "0");
                            CalculateEstimatedValue(dt, "0");

                            ViewState["dtIQMonthlyRent"] = dt;
                            clearMonthlyRentControls("0");


                            displayErrorMessage(lblmsg, "Saved successfully", MessageScope.Success);
                            btnAdd.Text = "Add";
                            hidtlidval.Value = "";


                            rdbTenure.Enabled = true;
                            rdbRenewal.Enabled = true;

                        }
                    }
                }
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::btnGetSQFT_Click", ex.ToString());
            }
        }

        public DataTable initiateMonthlyRentDT(DataTable dt)
        {
            DataTable dtReturn = null;
            if (dt == null)
                dt = new DataTable();
            dt.Columns.Add("ID");
            dt.Columns.Add("RentType");
            dt.Columns.Add("StartDate");
            dt.Columns.Add("EndDate");
            dt.Columns.Add("MonthlyRent");
            dt.Columns.Add("RentPerSQF");

            dtReturn = dt;
            return dtReturn;
        }

        private void displayErrorMessage(string strMessage, MessageScope msgScope)
        {
            lblErrorMsg.Text = strMessage;
            switch (msgScope)
            {
                case MessageScope.Error:
                    lblErrorMsg.ForeColor = Color.Red;
                    break;
                case MessageScope.Success:
                    lblErrorMsg.ForeColor = Color.Green;
                    break;
            }
            lblErrorMsg.Visible = true;
        }

        private void displayErrorMessage(Label lblmsg, string strMessage, MessageScope msgScope)
        {
            lblmsg.Text = strMessage;
            switch (msgScope)
            {
                case MessageScope.Error:
                    lblmsg.ForeColor = Color.Red;
                    break;
                case MessageScope.Success:
                    lblmsg.ForeColor = Color.Green;
                    break;
            }
            lblmsg.Visible = true;
        }

        private void hideMessage(Label lblMsg)
        {
            lblMsg.Text = "";
            lblMsg.ForeColor = Color.Black;
            lblMsg.Visible = false;
        }

        public bool checkForTRDateValidation(string strTenSecMode)
        {
            bool bReturn = false;
            try
            {
                DateTime dtS = DateTime.MinValue;
                DateTime dtE = DateTime.MinValue;
                DataTable dt = null;
                Label lblMsg = null;
                dtS = dtcTLStartDate.SelectedDate;
                dtE = dtcTLEndDate.SelectedDate;
                lblMsg = lblMonthlyRentMsg;
                dt = (DataTable)ViewState["dtIQMonthlyRent"];


                if (dtE <= dtS)
                {
                    bReturn = true;
                    displayErrorMessage(lblMsg, "Please select 'End Date' greater than 'Start Date'", MessageScope.Error);
                }


                using (SPWeb oWeb = site.OpenWeb())
                {
                    //sunilv
                    DateTime oLastEndDate;
                    int iSelectedUnitID = 0;
                    foreach (int i in lbxUnitNumber.GetSelectedIndices())
                    {
                        SPList UnitInfoList = oWeb.Lists[strUnitInformationList];
                        iSelectedUnitID = Convert.ToInt16(lbxUnitNumber.Items[i].Value);

                        SPListItem unitItem = UnitInfoList.GetItemById(iSelectedUnitID);
                        if (unitItem["LastLicenseEndDate"] != null)
                        {
                            if (unitItem["LastLicenseEndDate"].ToString().Trim() != "")
                            {
                                oLastEndDate = (DateTime)unitItem["LastLicenseEndDate"];
                                if (oLastEndDate.Date >= dtcTLStartDate.SelectedDate.Date)
                                {
                                    bReturn = true;
                                    displayErrorMessage(lblMsg, "Please select 'Start Date' greater than 'End Date' of selected units previous agreement.", MessageScope.Error);
                                }
                            }
                        }
                        else
                        {
                            //
                        }

                    }

                }






                //foreach (DataRow dr in dt.Rows)
                //{
                //    bool bCheck = false;
                //    if (!string.IsNullOrEmpty(hidIQTLIDValue.Value))
                //    {
                //        if (dr["ID"].ToString() != hidIQTLIDValue.Value)
                //            bCheck = true;
                //    }
                //    if (bCheck)
                //    {
                //        DateTime dtRowStart = DateTime.ParseExact(dr["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                //        DateTime dtRowEnd = DateTime.ParseExact(dr["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                //        bool bOverlap = dtE < dtRowEnd && dtRowStart <= dtE;
                //        if (bOverlap)
                //        {
                //            displayErrorMessage(lblMsg, "Dates are overlapping", MessageScope.Error);
                //            bReturn = true;
                //        }

                //        bOverlap = dtS < dtRowEnd && dtRowStart <= dtS;
                //        if (bOverlap)
                //        {
                //            displayErrorMessage(lblMsg, "Dates are overlapping", MessageScope.Error);
                //            bReturn = true;
                //        }
                //    }
                //}
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::checkForTRDateValidation", ex.ToString());
            }
            return bReturn;
        }

        public void clearMonthlyRentControls(string strTSecMode)
        {
            dtcTLStartDate.ClearSelection();
            dtcTLEndDate.ClearSelection();
            txtTLMonthlyRent.Text = "";
            txtTLRentPerSF.Text = "";

        }

        protected void txtTLMonthlyRent_TextChanged(object sender, EventArgs e)
        {
            hideMessage(lblMonthlyRentMsg);
            try
            {
                if (!string.IsNullOrEmpty(lblSQFT.Text.Trim()))
                {
                    TextBox oMonthlyRent = (TextBox)sender;
                    double dMonthlyRent = Convert.ToDouble(oMonthlyRent.Text);
                    double dRent = Math.Round(Convert.ToDouble(oMonthlyRent.Text) / Convert.ToDouble(lblSQFT.Text), 2);
                    txtTLRentPerSF.Text = dRent.ToString();
                }
                else displayErrorMessage(lblMonthlyRentMsg, "Please select the 'Unit Number'", MessageScope.Error);

            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::txtTLMonthlyRent_TextChanged", ex.ToString());
            }
        }

        protected void grvMonthlyRent_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            try
            {
                if (e.CommandName.ToLower() == "edittl")
                    EditMonthlyRent(e.CommandArgument.ToString());
                else if (e.CommandName.ToLower() == "deletetl")
                    DeleteMonthlyRent(e.CommandArgument.ToString());
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::grvMonthlyRent_RowCommand", ex.ToString());
            }
        }

        public void EditMonthlyRent(string strID)
        {
            try
            {
                DataTable dt = null;
                Label lblMsg = null;
                lblMsg = lblMonthlyRentMsg;
                hidIQTLIDValue.Value = strID;
                dt = (DataTable)ViewState["dtIQMonthlyRent"];

                hideMessage(lblMsg);
                if (!string.IsNullOrEmpty(strID))
                {
                    DataRow[] dr = dt.Select(string.Format("ID = '{0}'", strID));
                    if (dr.Length > 0)
                    {
                        try
                        {
                            dtcTLStartDate.SelectedDate = DateTime.ParseExact(dr[0]["StartDate"].ToString(), "d/M/yyyy", CultureInfo.InvariantCulture);
                        }
                        catch
                        {
                            dtcTLStartDate.SelectedDate = DateTime.ParseExact(dr[0]["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                        }
                        try
                        {
                            dtcTLEndDate.SelectedDate = DateTime.ParseExact(dr[0]["EndDate"].ToString(), "d/M/yyyy", CultureInfo.InvariantCulture);
                        }
                        catch
                        {
                            dtcTLEndDate.SelectedDate = DateTime.ParseExact(dr[0]["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                        }

                        txtTLMonthlyRent.Text = dr[0]["MonthlyRent"].ToString();
                        txtTLRentPerSF.Text = dr[0]["RentPerSQF"].ToString();
                        btnMonthlyRent.Text = "Save";
                        if (dr[0]["RentType"].ToString().ToLower() == "tenure")
                            rdbTenure.Checked = true;
                        else if (dr[0]["RentType"].ToString().ToLower() == "renewal")
                            rdbRenewal.Checked = true;
                        rdbTenure.Enabled = false;
                        rdbRenewal.Enabled = false;
                    }
                }
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::DisplayMonthlyRentForEdit", ex.ToString());
            }
        }

        public void DeleteMonthlyRent(string strID)
        {
            try
            {
                DataTable dt = null;
                Label lblMsg = null;
                lblMsg = lblMonthlyRentMsg;
                hidIQTLIDValue.Value = strID;
                dt = (DataTable)ViewState["dtIQMonthlyRent"];

                hideMessage(lblMsg);
                if (!string.IsNullOrEmpty(strID))
                {
                    DataRow[] dr = dt.Select(string.Format("ID = '{0}'", strID));
                    if (dr.Length > 0)
                    {
                        dt.Rows.Remove(dr[0]);
                        dt.AcceptChanges();
                        BindMonthlyRentGrid(dt, "0", true);
                        CalculateFirstLastBillingAmount(dt, "0");
                        CalculateEstimatedValue(dt, "0");
                    }
                }
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::DeleteMonthlyRent", ex.ToString());
            }
        }

        public void BindMonthlyRentGrid(DataTable dt, string strTenSecMode, bool reorderID)
        {
            try
            {
                if (reorderID)
                {
                    foreach (DataRow dr in dt.Rows)
                    {
                        dr["ID"] = (dt.Rows.IndexOf(dr) + 1).ToString();
                    }
                    dt.AcceptChanges();
                }
                ViewState["dtIQMonthlyRent"] = dt;
                grvMonthlyRent.DataSource = dt;
                grvMonthlyRent.DataBind();
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::BindMonthlyRentGrid", ex.ToString());
            }
        }

        public void CalculateFirstLastBillingAmount(DataTable dt, string strTenSecMode)
        {
            try
            {
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow[] drs = dt.Select(string.Format("RentType = '{0}'", "Tenure"));
                    if (drs.Length > 0)
                    {
                        double dMonthlyRent = Convert.ToDouble(drs[0]["MonthlyRent"].ToString());
                        DateTime TSD = DateTime.ParseExact(drs[0]["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                        int iDays = DateTime.DaysInMonth(TSD.Year, TSD.Month);
                        if (TSD.Day != 1)
                        {
                            int iBalDays = iDays - TSD.Day + 1;
                            double dBalanceDays = (double)iBalDays / (double)iDays;
                            // if (strTenSecMode == "2")
                            lblIQFirsrBA.Text = Math.Round(dBalanceDays * dMonthlyRent, 2).ToString();
                            // lbltempbalancedaysFirst.Text = dBalanceDays;
                            lbltempbalancedaysFirst.Text = Convert.ToString(dBalanceDays);
                        }
                    }
                    DataRow dr;
                    if (drs.Length > 1)
                        dr = drs[drs.Length - 1];
                    else dr = drs[0];
                    double dEMonthlyRent = Convert.ToDouble(dr["MonthlyRent"].ToString());
                    DateTime TED = DateTime.ParseExact(dr["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                    int iEDays = DateTime.DaysInMonth(TED.Year, TED.Month);
                    if (TED.Day != iEDays)
                    {
                        int iBalDays = TED.Day;
                        double dBalanceDays = (double)iBalDays / (double)iEDays;
                        // if (strTenSecMode == "2")
                        lblIQLastBA.Text = Math.Round(dBalanceDays * dEMonthlyRent, 2).ToString();
                        lbltempbalancedaysLast.Text = Convert.ToString(dBalanceDays);
                    }
                }
                else
                {
                    lblIQFirsrBA.Text = "";
                    lblIQLastBA.Text = "";
                }
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::CalculateFirstLastBillingAmount", ex.ToString());
            }
        }

        public void CalculateEstimatedValue(DataTable dt, string strTenSecMode)
        {
            try
            {
                // if (rdoTypeOption1.Checked) 
                //{			

                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow[] drsTenure = dt.Select(string.Format("RentType = '{0}'", "Tenure"));
                    double dblTotalEstValue = 0;
                    DateTime dtTLED = DateTime.MinValue;
                    double dblTLA = 0;
                    if (drsTenure.Length > 0)
                    {
                        int i = 0;
                        foreach (DataRow dr in drsTenure)
                        {
                            i++;
                            if (drsTenure.Length == i)
                            {
                                dtTLED = DateTime.ParseExact(dr["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                                dblTLA = Convert.ToDouble(dr["MonthlyRent"].ToString());
                            }
                            DateTime dtTSD = DateTime.ParseExact(dr["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                            DateTime dtTED = DateTime.ParseExact(dr["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                            lblRenewalMonthlyRent.Text = dr["MonthlyRent"].ToString();
                            //RenewalMonthlyRent = Convert.ToDouble(dr["MonthlyRent"].ToString());
                            double dblRent = Convert.ToDouble(dr["MonthlyRent"].ToString());

                            // sk chnages

                            CalculateYMD(dtTSD, dtTED);
                            int iDays = DateTime.DaysInMonth(dtTED.Year, dtTED.Month); // calculate days in a months
                            double dblTotalMonths = ((double)aintNoOfYears * 12 + (double)aintNoOfMonths + (double)aintNoOfDays / (double)iDays);
                            double dblTemEstVal = Math.Round(dblTotalMonths, 3) * dblRent;
                            dblTotalEstValue += dblTemEstVal;



                            preserverowno += 1;

                            if (dt.Rows.Count == preserverowno)
                            {



                                if (!string.IsNullOrEmpty(txtRenewalYear.Text.Trim()))
                                    aintNoOfYears = Convert.ToInt16(txtRenewalYear.Text.Trim());
                                if (!string.IsNullOrEmpty(txtRenewalMonth.Text.Trim()))
                                    aintNoOfMonths = Convert.ToInt16(txtRenewalMonth.Text.Trim());
                                if (!string.IsNullOrEmpty(txtRenewalDay.Text.Trim()))
                                    aintNoOfDays = Convert.ToInt16(txtRenewalDay.Text.Trim());
                                //get end date of renewal
                                int NoOfRenewalDays = aintNoOfYears * 365 + aintNoOfMonths * 30 + aintNoOfDays;

                                DateTime dtFEDY = dtTED.AddYears(aintNoOfYears);
                                DateTime dtFEDM = dtFEDY.AddMonths(aintNoOfMonths);
                                DateTime dtFED = dtFEDM.AddDays(aintNoOfDays);
                                int irDays = DateTime.DaysInMonth(dtFED.Year, dtFED.Month); // calculate days in a months
                                                                                            //DateTime.ParseExact(dr["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                                                                                            //end

                                dblTotalMonths = ((double)aintNoOfYears * 12 + (double)aintNoOfMonths + (double)aintNoOfDays / (double)irDays);
                                // dblTotalMonths = (aintNoOfYears * 12 + aintNoOfMonths + aintNoOfDays / 30.00);
                                dblTemEstVal = Math.Round(dblTotalMonths, 3) * dblRent;
                                dblTotalEstValue += dblTemEstVal;
                            }


                            // end chnages


                        }
                    }
                    DataRow[] drsRenewal = dt.Select(string.Format("RentType = '{0}'", "Renewal"));
                    if (drsRenewal.Length > 0)
                    {
                        foreach (DataRow dr in drsRenewal)
                        {
                            //  DateTime dtTSD = DateTime.ParseExact(dr["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                            //  DateTime dtTED = DateTime.ParseExact(dr["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                            //   double dblRent = Convert.ToDouble(dr["MonthlyRent"].ToString());
                            // double dblTotalMonths = (((dtTED.Year - dtTSD.Year) * 12) + dtTED.Month - dtTSD.Month);
                            //  double dblTemEstVal = Math.Round(dblTotalMonths, 2) * dblRent;
                            //  dblTotalEstValue += dblTemEstVal;
                        }
                    }
                    else
                    {
                        /*

                          DateTime dtR = DateTime.MinValue;
                          if (dtTLED != DateTime.MinValue)
                              dtR = dtTLED;
                          if (!string.IsNullOrEmpty(txtRenewalYear.Text.Trim()))
                              dtR = dtR.AddYears(Convert.ToInt16(txtRenewalYear.Text.Trim()));
                          if (!string.IsNullOrEmpty(txtRenewalMonth.Text.Trim()))
                              dtR = dtR.AddMonths(Convert.ToInt16(txtRenewalMonth.Text.Trim()));
                          if (!string.IsNullOrEmpty(txtRenewalDay.Text.Trim()))
                              dtR = dtR.AddDays(Convert.ToDouble(txtRenewalDay.Text.Trim()));
                          double dblRTotalMonths = (((dtR.Year - dtTLED.Year) * 12) + dtR.Month - dtTLED.Month);
                          dblTotalEstValue += (dblRTotalMonths * dblTLA);

                          */
                    }

                    //  txtContractValue.Text = dblTotalEstValue.ToString();
                    txtContractValue.Text = (Math.Round(dblTotalEstValue, 2)).ToString();

                    CalculateApprovalAuthority(dblTotalEstValue);
                }
                //	} //PH2 
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::CalculateEstimatedValue", ex.ToString());
            }
        }

        private void CalculateApprovalAuthority(double dblTotalEstValue)
        {
            try
            {
                DateTime dtApprovalDate = DateTime.ParseExact("01/07/2016", "dd/MM/yyyy", CultureInfo.InvariantCulture);
                DateTime dtAwardDate = DateTime.MinValue;
                TextBox lblAA = null;
                //dtAwardDate = dtInvAwardDate.SelectedDate;
                lblAA = lblApprovingAuthority;

                if (dtAwardDate < dtApprovalDate)
                {
                    if (dblTotalEstValue <= 100000)
                        lblAA.Text = "Constituency Tender Committee";
                    else if (dblTotalEstValue > 100000 && dblTotalEstValue <= 1000000)
                        lblAA.Text = "Tender Board A";
                    else if (dblTotalEstValue > 1000000 && dblTotalEstValue <= 10000000)
                        lblAA.Text = "Tender Board B";
                    else if (dblTotalEstValue > 10000000)
                        lblAA.Text = "Tender Board C";
                }
                else
                {
                    if (dblTotalEstValue <= 250000)
                        lblAA.Text = "Constituency Tender Committee";
                    else if (dblTotalEstValue > 250000 && dblTotalEstValue <= 1000000)
                        lblAA.Text = "Tender Board A";
                    else if (dblTotalEstValue > 1000000 && dblTotalEstValue <= 10000000)
                        lblAA.Text = "Tender Board B";
                    else if (dblTotalEstValue > 10000000)
                        lblAA.Text = "Tender Board C";
                }
            }
            catch (Exception ex)
            {
                AddToLogFile(strErrorTitle + "::CalculateApprovalAuthority", ex.ToString());
            }
        }
        // method to get years, momths and days

        public void CalculateYMD(DateTime startdate, DateTime enddate)
        {
            // get current date.

            aintNoOfDays = 0;
            aintNoOfMonths = 0;
            aintNoOfYears = 0;
            DateTime adtCurrentDate = enddate.AddDays(1);
            DateTime adtDateOfBirth = startdate;

            // find the literal difference
            aintNoOfDays = adtCurrentDate.Day - adtDateOfBirth.Day;
            aintNoOfMonths = adtCurrentDate.Month - adtDateOfBirth.Month;
            aintNoOfYears = adtCurrentDate.Year - adtDateOfBirth.Year;

            if (aintNoOfDays < 0)
            {
                aintNoOfDays += DateTime.DaysInMonth(adtCurrentDate.Year, adtCurrentDate.Month);
                aintNoOfMonths--;
            }

            if (aintNoOfMonths < 0)
            {
                aintNoOfMonths += 12;
                aintNoOfYears--;
            }
        }

        // end calculation
        //end method


        private void BindLeaseAgreementLicense(string strSecMode)
        {
            try
            {
                string LeaseAgreeID = string.Empty;
                if (Request.QueryString["drID"] != null && !string.IsNullOrEmpty(Request.QueryString["drID"].ToString()))
                    LeaseAgreeID = Request.QueryString["drID"].ToString();
                else if (Request.QueryString["rID"] != null && !string.IsNullOrEmpty(Request.QueryString["rID"].ToString()))
                    LeaseAgreeID = Request.QueryString["rID"].ToString();
                DataTable dtCurrentTable = null;
                dtCurrentTable = initiateMonthlyRentDT(dtCurrentTable);
                double dblFirstBA = 0;
                double dblLastBA = 0;
                string SiteURL = SPContext.Current.Web.Url;
                string strListName = string.Empty;
                //   if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2 draft
                if (mRecord != "Draft") //ph2 draft
                {
                    strListName = strTestTenantList;
                }
                else
                {
                    strListName = strTestTenantListDraft;
                }
                using (SPSite SiteCollection = new SPSite(SiteURL))
                {
                    using (SPWeb Site = SiteCollection.OpenWeb())
                    {
                        SPList lstLALicense = Site.Lists[strListName];
                        if (lstLALicense != null)
                        {
                            SPQuery query = new SPQuery();

                            query.Query = string.Format(@"<Where>
                                                          <Eq>
                                                             <FieldRef Name='TenancyAgreementID' />
                                                             <Value Type='Text'>{0}</Value>
                                                          </Eq>
                                                       </Where>", LeaseAgreeID);
                            SPListItemCollection items = lstLALicense.GetItems(query);
                            if (items != null && items.Count > 0)
                            {
                                int i = 0;
                                foreach (SPListItem item in items)
                                {
                                    i++;
                                    DataRow dr = dtCurrentTable.NewRow();
                                    dr["ID"] = i.ToString();
                                    dr["StartDate"] = Convert.ToDateTime(item["LicenseStartDate"].ToString()).ToString("dd/MM/yyyy");
                                    dr["EndDate"] = Convert.ToDateTime(item["LicenseEndDate"].ToString()).ToString("dd/MM/yyyy");
                                    dr["MonthlyRent"] = (string)TMSCommon.NoNull(item["MonthlyRent"], string.Empty);
                                    dr["RentPerSQF"] = (string)TMSCommon.NoNull(item["RentPSF"], string.Empty);
                                    dr["RentType"] = (string)TMSCommon.NoNull(item["TRType"], "Tenure");
                                    if (item["NetFirstRent"] != null && !string.IsNullOrEmpty(item["NetFirstRent"].ToString()))
                                        dblFirstBA = Convert.ToDouble(item["NetFirstRent"].ToString());
                                    else dblFirstBA = 0;
                                    if (item["NetLastRent"] != null && !string.IsNullOrEmpty(item["NetLastRent"].ToString()))
                                        dblLastBA = Convert.ToDouble(item["NetLastRent"].ToString());
                                    else dblLastBA = 0;
                                    dtCurrentTable.Rows.Add(dr);
                                }

                                ViewState["dtIQMonthlyRent"] = dtCurrentTable;
                                grvMonthlyRent.DataSource = dtCurrentTable;
                                grvMonthlyRent.DataBind();
                                lblIQFirsrBA.Text = dblFirstBA.ToString();
                                lblIQLastBA.Text = dblLastBA.ToString();

                                CalculateFirstLastBillingAmount(dtCurrentTable, strSecMode);
                                CalculateEstimatedValue(dtCurrentTable, strSecMode);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                displayErrorMessage(ex.ToString(), MessageScope.Error);
                AddToLogFile(strErrorTitle + "::BindLeaseAgreementLicense", ex.ToString());
            }
        }

        private void AddLeaseAgreementLicenseDraft(string strLeaseNo, ref DateTime dtLastEndDate)
        {
            Regex rAmount = new Regex("^[0-9]+([.,][0-9]{1,2})?$");
            try
            {
                //SetRowData();
                DataTable table = null;
                string strListName = string.Empty;
                //  if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2 draft
                //	if (drpAgreementStatus.SelectedItem.Text != "Submit for Approval") //ph2 draft


                //   strListName = strTestTenantList;

                strListName = strTestTenantListDraft;

                table = (DataTable)ViewState["dtIQMonthlyRent"];
                if (table != null && table.Rows.Count > 0)
                {
                    string SiteURL = SPContext.Current.Web.Url;

                    using (SPSite SiteCollection = new SPSite(SiteURL))
                    {
                        using (SPWeb Site = SiteCollection.OpenWeb())
                        {
                            SPList lstLAL = Site.Lists[strListName];
                            SPListItem newItem = null;

                            //  CheckAndDeleteExistingLA(strLeaseNo);
                            foreach (DataRow row in table.Rows)
                            {
                                string ComplianceTitle1 = row["StartDate"].ToString();
                                string ComplianceTitle2 = row["EndDate"].ToString();
                                string ComplianceTitle3 = row["MonthlyRent"].ToString();
                                string ComplianceTitle4 = row["RentPerSQF"].ToString();
                                string ComplianceTitle6 = string.Empty;
                                string ComplianceTitle7 = string.Empty;
                                ComplianceTitle6 = lblIQFirsrBA.Text;
                                ComplianceTitle7 = lblIQLastBA.Text;


                                if (!string.IsNullOrEmpty(ComplianceTitle1) && !string.IsNullOrEmpty(ComplianceTitle2) &&
                                    !string.IsNullOrEmpty(ComplianceTitle3) && !string.IsNullOrEmpty(ComplianceTitle4))
                                {
                                    newItem = lstLAL.Items.Add();
                                    newItem["TenancyAgreementID"] = strLeaseNo;
                                    //newItem["LeaseCategory"] = ddlTenantSecMode.SelectedItem.Text;
                                    newItem["LicenseStartDate"] = DateTime.ParseExact(ComplianceTitle1, "dd/MM/yyyy", CultureInfo.InstalledUICulture).ToString("MM/dd/yyyy"); //Convert.ToDateTime(ComplianceTitle1).ToString("dd/MM/yyyy");
                                    newItem["LicenseEndDate"] = DateTime.ParseExact(ComplianceTitle2, "dd/MM/yyyy", CultureInfo.InstalledUICulture).ToString("MM/dd/yyyy");
                                    dtLastEndDate = Convert.ToDateTime(DateTime.ParseExact(ComplianceTitle2, "dd/MM/yyyy", CultureInfo.InstalledUICulture).ToString("MM/dd/yyyy"));
                                    if (ComplianceTitle3.Trim() != "")
                                    {
                                        if (rAmount.IsMatch(ComplianceTitle3.Trim()))
                                            newItem["MonthlyRent"] = ComplianceTitle3;
                                        else
                                        {
                                            displayErrorMessage("Monthly Rent field should contain only numbers.", MessageScope.Error);
                                            return;
                                        }
                                    }
                                    else
                                        newItem["MonthlyRent"] = "0.00";
                                    if (ComplianceTitle4.Trim() != "")
                                    {
                                        if (rAmount.IsMatch(ComplianceTitle4.Trim()))
                                            newItem["RentPSF"] = ComplianceTitle4;
                                        else
                                        {
                                            displayErrorMessage("Monthly Rent field should contain only numbers.", MessageScope.Error);
                                            return;
                                        }
                                    }
                                    else
                                        newItem["RentPSF"] = "0.00";
                                    if (!string.IsNullOrEmpty(ComplianceTitle6.Trim()))
                                        newItem["NetFirstRent"] = ComplianceTitle6;

                                    if (!string.IsNullOrEmpty(ComplianceTitle7.Trim()))
                                        newItem["NetLastRent"] = ComplianceTitle7;

                                    newItem["AgreementSQFT"] = lblSQFT.Text;
                                    newItem["CCName"] = ddlCCName.SelectedValue;
                                    newItem["TRType"] = row["RentType"].ToString();
                                    newItem.Update();
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                displayErrorMessage(ex.ToString(), MessageScope.Error);
                AddToLogFile(strErrorTitle + "::AddLeaseAgreementLicenseDraft", ex.ToString());
            }
        }

        //
        private void AddLeaseAgreementLicenseSave(string strLeaseNo, ref DateTime dtLastEndDate)
        {
            Regex rAmount = new Regex("^[0-9]+([.,][0-9]{1,2})?$");
            try
            {
                //SetRowData();
                DataTable table = null;
                string strListName = string.Empty;


                strListName = strTestTenantList;



                table = (DataTable)ViewState["dtIQMonthlyRent"];
                if (table != null && table.Rows.Count > 0)
                {
                    string SiteURL = SPContext.Current.Web.Url;

                    using (SPSite SiteCollection = new SPSite(SiteURL))
                    {
                        using (SPWeb Site = SiteCollection.OpenWeb())
                        {
                            SPList lstLAL = Site.Lists[strListName];
                            SPListItem newItem = null;

                            //  CheckAndDeleteExistingLA(strLeaseNo);
                            foreach (DataRow row in table.Rows)
                            {
                                string ComplianceTitle1 = row["StartDate"].ToString();
                                string ComplianceTitle2 = row["EndDate"].ToString();
                                string ComplianceTitle3 = row["MonthlyRent"].ToString();
                                string ComplianceTitle4 = row["RentPerSQF"].ToString();
                                string ComplianceTitle6 = string.Empty;
                                string ComplianceTitle7 = string.Empty;
                                ComplianceTitle6 = lblIQFirsrBA.Text;
                                ComplianceTitle7 = lblIQLastBA.Text;


                                if (!string.IsNullOrEmpty(ComplianceTitle1) && !string.IsNullOrEmpty(ComplianceTitle2) &&
                                    !string.IsNullOrEmpty(ComplianceTitle3) && !string.IsNullOrEmpty(ComplianceTitle4))
                                {
                                    newItem = lstLAL.Items.Add();
                                    newItem["TenancyAgreementID"] = strLeaseNo;
                                    //newItem["LeaseCategory"] = ddlTenantSecMode.SelectedItem.Text;
                                    newItem["LicenseStartDate"] = DateTime.ParseExact(ComplianceTitle1, "dd/MM/yyyy", CultureInfo.InstalledUICulture).ToString("MM/dd/yyyy"); //Convert.ToDateTime(ComplianceTitle1).ToString("dd/MM/yyyy");
                                    newItem["LicenseEndDate"] = DateTime.ParseExact(ComplianceTitle2, "dd/MM/yyyy", CultureInfo.InstalledUICulture).ToString("MM/dd/yyyy");
                                    dtLastEndDate = Convert.ToDateTime(DateTime.ParseExact(ComplianceTitle2, "dd/MM/yyyy", CultureInfo.InstalledUICulture).ToString("MM/dd/yyyy"));

                                    if (ComplianceTitle3.Trim() != "")
                                    {
                                        if (rAmount.IsMatch(ComplianceTitle3.Trim()))
                                            newItem["MonthlyRent"] = ComplianceTitle3;
                                        else
                                        {
                                            displayErrorMessage("Monthly Rent field should contain only numbers.", MessageScope.Error);
                                            return;
                                        }
                                    }
                                    else
                                        newItem["MonthlyRent"] = "0.00";
                                    if (ComplianceTitle4.Trim() != "")
                                    {
                                        if (rAmount.IsMatch(ComplianceTitle4.Trim()))
                                            newItem["RentPSF"] = ComplianceTitle4;
                                        else
                                        {
                                            displayErrorMessage("Monthly Rent field should contain only numbers.", MessageScope.Error);
                                            return;
                                        }
                                    }
                                    else
                                        newItem["RentPSF"] = "0.00";
                                    if (!string.IsNullOrEmpty(ComplianceTitle6.Trim()))
                                        newItem["NetFirstRent"] = ComplianceTitle6;

                                    if (!string.IsNullOrEmpty(ComplianceTitle7.Trim()))
                                        newItem["NetLastRent"] = ComplianceTitle7;

                                    newItem["AgreementSQFT"] = lblSQFT.Text;
                                    newItem["CCName"] = ddlCCName.SelectedValue;
                                    newItem["TRType"] = row["RentType"].ToString();
                                    newItem.Update();
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                displayErrorMessage(ex.ToString(), MessageScope.Error);
                AddToLogFile(strErrorTitle + "::AddLeaseAgreementLicense", ex.ToString());
            }
        }


        //

        // delete all licenses
        private void DeleteLeaseAgreementLicenseDraft(string strLeaseNo)
        {


            //	string strListName = string.Empty;

            SPWeb web = site.OpenWeb();
            SPList strListName;


            //	if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2 draft
            //	if (drpAgreementStatus.SelectedItem.Text != "Submit for Approval") //ph2 draft


            strListName = web.Lists[strTestTenantListDraft];


            // DELETE LICENSE LIST
            SPQuery oLicQueryDraft = new SPQuery();
            oLicQueryDraft.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID' /><Value Type='Text'>" + strLeaseNo + "</Value></Eq></Where>";
            SPListItemCollection LicenseListCollectionDraft = strListName.GetItems(oLicQueryDraft);
            int countItem = LicenseListCollectionDraft.Count;
            for (int i = 0; i < countItem; i++)
            {
                LicenseListCollectionDraft.Delete(0);
            }

        }


        //end



        private void DeleteLeaseAgreementLicenseSave(string strLeaseNo)
        {


            //	string strListName = string.Empty;

            SPWeb web = site.OpenWeb();
            SPList strListName;


            //	if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2 draft
            //	if (drpAgreementStatus.SelectedItem.Text != "Submit for Approval") //ph2 draft


            strListName = web.Lists[strTestTenantList];


            // DELETE LICENSE LIST
            SPQuery oLicQueryDraft = new SPQuery();
            oLicQueryDraft.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID' /><Value Type='Text'>" + strLeaseNo + "</Value></Eq></Where>";
            SPListItemCollection LicenseListCollectionDraft = strListName.GetItems(oLicQueryDraft);
            int countItem = LicenseListCollectionDraft.Count;
            for (int i = 0; i < countItem; i++)
            {
                LicenseListCollectionDraft.Delete(0);
            }

        }


        //end



        private void CheckAndDeleteExistingLA(string strLeaseNo)
        {
            try
            {
                string SiteURL = SPContext.Current.Web.Url;
                using (SPSite SiteCollection = new SPSite(SiteURL))
                {
                    using (SPWeb Site = SiteCollection.OpenWeb())
                    {
                        bool bUnsafe = Site.AllowUnsafeUpdates;
                        Site.AllowUnsafeUpdates = true;
                        SPList lstLA = Site.Lists[strTestTenantList];
                        if (lstLA != null)
                        {
                            SPQuery query = new SPQuery();
                            query.Query = string.Format(@"<Where>
                                                          <Eq>
                                                             <FieldRef Name='LeaseAgreementID' />
                                                             <Value Type='Text'>{0}</Value>
                                                          </Eq>
                                                       </Where>", strLeaseNo);
                            SPListItemCollection items = lstLA.GetItems(query);
                            if (items != null && items.Count > 0)
                            {
                                StringBuilder batchString = new StringBuilder();
                                batchString.Append("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Batch>");

                                foreach (SPListItem item in items)
                                {
                                    batchString.Append("<Method>");
                                    batchString.Append("<SetList Scope=\"Request\">" + lstLA.ID.ToString() + "</SetList>");
                                    batchString.Append("<SetVar Name=\"ID\">" + item.ID.ToString() + "</SetVar>");
                                    batchString.Append("<SetVar Name=\"Cmd\">Delete</SetVar>");
                                    batchString.Append("</Method>");
                                }
                                batchString.Append("</Batch>");
                                Site.ProcessBatchData(batchString.ToString());
                            }
                        }
                        Site.AllowUnsafeUpdates = bUnsafe;
                    }
                }
            }
            catch (Exception ex)
            {
                displayErrorMessage(ex.ToString(), MessageScope.Error);
                AddToLogFile(strErrorTitle + "::CheckAndDeleteExistingLA", ex.ToString());
            }
        }

        #endregion




        protected void LoadAgreementForm()
        {

            SPWeb web = null;

            SPSecurity.RunWithElevatedPrivileges(delegate ()
            {
                web = site.OpenWeb();
                //Page.Validate();
            });


            ddlCCName.Items.Add("Select CC Name");
            lbxUnitNumber.Items.Add("Select Unit Number");
            ddlTenantName.Items.Add("Select Company Name"); // added by SK
                                                            //	ddlOtherFees.Items.Add("Select Other Fee"); // ph2
            bindCCName();
            bindTradeCategory();
            bindCompanyName(); // added by sk call function to get company names from Tenant Mster
            bindOtherFees(); // ph2

            ddlTradeType.Items.Add(new ListItem("Select Trade Type"));
            drpAgreementStatus.Items.Add("Select Agreement Status");

            //if user is a BDGroup member...
            if (GetGroups(BDGroup))
            {
                //lblTest.Text = "In BD Group";
                drpAgreementStatus.Items.Add(new ListItem("Approved", "Approved"));
                drpAgreementStatus.Items.Add(new ListItem("Rejected", "Rejected"));
                drpAgreementStatus.Items.Add(new ListItem("Pending for Approval", "Pending for Approval"));
                drpAgreementStatus.Items.Add(new ListItem("ReSubmission", "ReSubmission")); //ph2 new status may need to remove
                                                                                            //	drpAgreementStatus.Items.Add(new ListItem("Draft", "Draft")); //ph2 new status may need to remove
                drpAgreementStatus.Items.Add(new ListItem("Cancelled", "Cancelled")); //ph2 new status may need to remove
                drpAgreementStatus.Items.Add(new ListItem("Deleted", "Deleted")); //ph2 new status may need to remove
            }
            else
            {
                //lblTest.Text = "Not In BD Group";
                drpAgreementStatus.Items.Add(new ListItem("Submit for Approval", "Submit for Approval"));
                //	drpAgreementStatus.Items.Add(new ListItem("Draft", "Draft")); //ph2 new status
            }

            if (!bEdit)
            {
                // create new agreement...
                //create draft agreement
                btnSave.Visible = false;
                lblselectedUnitnos.Visible = false;
                drpAgreementStatus.Visible = false;
                string mode = "Draft";
                genTenancyRecordNumber(mode);
                updateTenancyRecordNumber(mode);


            }
            else
            {
                //edit existing agreement...



                //ph2 start

                SPList TAList;

                if (mRecord == "Draft")
                {
                    iRecord = Convert.ToInt32(Request.QueryString["drID"]);
                    TAList = web.Lists[strAgreementListNameDraft];
                }
                else
                {
                    iRecord = Convert.ToInt32(Request.QueryString["rID"]);
                    TAList = web.Lists[strAgreementListName];
                }


                //ph2 end





                SPListItem recordItem = TAList.GetItemById(iRecord);


                lblRecordNumber.Text = recordItem["TenancyRecordNumber"].ToString();

                // to get novation and renewal type

                if (recordItem["AgreementCategory"] != null)
                {
                    sAgreementCategory = recordItem["AgreementCategory"].ToString();
                }
                if (recordItem["TenancyRecordType"] != null)
                {
                    sTenancyRecordType = recordItem["TenancyRecordType"].ToString();
                }
                //end


                if (recordItem["CCName"] != null)
                {
                    ddlCCName.SelectedValue = recordItem["CCName"].ToString();
                    ddlCCName_SelectedIndexChanged(ddlCCName, EventArgs.Empty);
                }

                if (recordItem["CCUnitNumber"] != null)
                {
                    string sUnits = recordItem["CCUnitNumber"].ToString().Trim();
                    sUnits = sUnits.TrimEnd(',');
                    string sUnitType = recordItem["CCUnitNumber"].ToString();
                    // string sUnitType = recordItem["UnitType"].ToString();

                    if (sUnitType == "Single")
                    {
                        lbxUnitNumber.SelectionMode = ListSelectionMode.Single;
                        for (int j = 0; j < lbxUnitNumber.Items.Count; j++)
                        {
                            if (lbxUnitNumber.Items[j].Value == sUnits.Trim())
                            {
                                // lbxUnitNumber.Items[j].Selected = true;
                                string svalue = lbxUnitNumber.Items[j].Value;
                                lbxUnitNumber.Items[j].Selected = true;
                                // lbxUnitNumber.SelectedValue = svalue;
                                // ph2 
                                int unitid = Convert.ToInt32(svalue);
                                unitadd(unitid);  // update selected list				
                                                  //ph2		
                            }
                        }
                    }
                    else
                    {
                        string[] values = sUnits.Split(',');
                        lbxUnitNumber.SelectionMode = ListSelectionMode.Multiple;
                        for (int i = 0; i < values.Length; i++)
                        {
                            for (int j = 0; j < lbxUnitNumber.Items.Count; j++)
                            {
                                if (lbxUnitNumber.Items[j].Value == values[i])
                                {
                                    lbxUnitNumber.Items[j].Selected = true;
                                    string svalue = lbxUnitNumber.Items[j].Value;
                                    // lbxUnitNumber.Items[j].Selected = true;
                                    // lbxUnitNumber.SelectedValue = svalue;
                                    // ph2 
                                    int unitid = Convert.ToInt32(svalue);
                                    unitadd(unitid);  // update selected list				
                                                      //ph2		
                                }
                            }
                        }
                    }

                    //AddToLogFile("LoadAgreementForm", sUnits + " == " + sUnits.IndexOf(","));
                    //AddToLogFile("LoadAgreementForm", sUnits + " == " + values.GetValue(0) + "  ==== " + lbxUnitNumber.Items.Count);

                    btnGetSQFT_Click(lbxUnitNumber, EventArgs.Empty);
                }
                if (recordItem["TenancyRecordType"] != null)
                {
                    if (recordItem["TenancyRecordType"].ToString() == "New")
                    {
                        rdoTypeOption1.Checked = true;
                        lblPageName.Text = "Add Agreement (Tenancy)";
                    }
                    else if (recordItem["TenancyRecordType"].ToString() == "Renewal")
                    {
                        rdoTypeOption2.Checked = true;
                        lblPageName.Text = "Renew Agreement (Tenancy)";
                    }
                    else if (recordItem["TenancyRecordType"].ToString() == "Extension")
                    {
                        rdoTypeOption3.Checked = true;
                        lblPageName.Text = "Extension Agreement (Tenancy)";
                    }
                }

                if (recordItem["AgreementCategory"].ToString() == "Novation")
                {
                    rdoTypeOption3.Checked = true;
                    lblPageName.Text = "Novation Agreement (Tenancy)";
                }

                // PH2 CHANGES RENEWAL

                if (flagmode == "R")
                {
                    rdoTypeOption2.Checked = true;
                }

                // ph2 for renewal




                //END


                //END PH2



                if (recordItem["UnitType"] != null)
                {
                    if (recordItem["UnitType"].ToString() == "Single")
                    {
                        rdoUnitOption1.Checked = true;
                    }
                    else
                    {
                        rdoUnitOption2.Checked = true;
                    }
                }

                //ph2 new control

                if (recordItem["PaymentOption"] != null)
                {
                    if (recordItem["PaymentOption"].ToString() == "Monthly")
                    {
                        rdopaymentoption1.Checked = true;
                    }
                    else
                    {
                        rdopaymentoption2.Checked = true;
                    }
                }


                // ph2 to take care old records


                if (recordItem["LatePaymentInterestRateOption"] == null)
                {
                    rdofixedlatepayment.Checked = true;
                }

                // for ph2

                if (recordItem["LatePaymentInterestRate"] != null)
                {
                    txtLatePayment.Text = recordItem["LatePaymentInterestRate"].ToString();
                }

                if (recordItem["LatePaymentInterestRateOption"] != null)
                {
                    if (recordItem["LatePaymentInterestRateOption"].ToString() == "Fixed")
                    {
                        rdofixedlatepayment.Checked = true;
                    }
                    else
                    {
                        rdovariablelatepayment.Checked = true;
                        getprevalingIntRate();    //ph2 always get updated info

                    }
                }

                //end control



                // end



                if (recordItem["TypeOfAgreement"] != null)
                {
                    if (recordItem["TypeOfAgreement"].ToString() == "Tenancy")
                    {
                        rdoAgreementOption1.Checked = true;
                    }
                    else
                    {
                        rdoAgreementOption2.Checked = true;
                    }
                }
                if (recordItem["TenantName"] != null)
                {

                    //ph2 to keep drop down

                    ddlTenantName.SelectedItem.Text = recordItem["TenantName"].ToString();

                    //end ph2 

                }
                if (recordItem["TenantTradingName"] != null)
                {
                    txtTradingName.Text = recordItem["TenantTradingName"].ToString();
                }
                if (recordItem["TypeOfCompany"] != null)
                {
                    //removed by SK PH2 ddlcompanytype replaced with txtcompanytype

                    // ddlCompanyType.SelectedValue = recordItem["TypeOfCompany"].ToString();
                    txtCompanyType.Text = recordItem["TypeOfCompany"].ToString(); // added by SK for new text field
                }
                if (recordItem["ROCUEN"] != null)
                {
                    txtROCNumber.Text = recordItem["ROCUEN"].ToString();
                }

                if (recordItem["IDNumber"] != null)
                {
                    txtFIN.Text = recordItem["IDNumber"].ToString();
                }
                if (recordItem["PersonInCharge"] != null)
                {
                    txtPersonInCharge.Text = recordItem["PersonInCharge"].ToString();
                }
                if (recordItem["RegisteredAddress"] != null)
                {
                    txtRegisteredAdd.Text = recordItem["RegisteredAddress"].ToString();
                }
                if (recordItem["OfficeNumber"] != null)
                {
                    txtOffNumber.Text = recordItem["OfficeNumber"].ToString();
                }
                if (recordItem["HandPhoneNumber"] != null)
                {
                    txtPhoneNumber.Text = recordItem["HandPhoneNumber"].ToString();
                }
                if (recordItem["EmailAddress"] != null)
                {
                    txtEmail.Text = recordItem["EmailAddress"].ToString();
                }
                if (recordItem["TradeCategory"] != null)
                {
                    ddlTradeCat.Items.FindByText(recordItem["TradeCategory"].ToString()).Selected = true;
                    ddlTradeCat_SelectedIndexChanged(ddlTradeCat, EventArgs.Empty);
                }
                if (recordItem["TypeOfTrade"] != null)
                {
                    ddlTradeType.SelectedValue = recordItem["TypeOfTrade"].ToString();
                }
                if (recordItem["ServiceCharges"] != null)
                {
                    txtServiceChgs.Text = recordItem["ServiceCharges"].ToString();
                }
                if (recordItem["SpaceClassification"] != null)
                {
                    if (recordItem["SpaceClassification"].ToString() == "Commercial")
                    {
                        rdoSpace1.Checked = true;
                    }

                    if (recordItem["SpaceClassification"].ToString() == "C & CI")
                    {
                        rdoSpace2.Checked = true;
                    }

                    if (recordItem["SpaceClassification"].ToString() == "Utility")
                    {
                        rdoSpace3.Checked = true;
                    }
                }

                if (recordItem["Tenure"] != null)
                {
                    string[] sTenureArr = recordItem["Tenure"].ToString().Split('-');

                    txtTenureYear.Text = sTenureArr[0];
                    txtTenureMonth.Text = sTenureArr[1];
                    txtTenureDay.Text = sTenureArr[2];
                }
                if (recordItem["RentalDueDate"] != null)
                {
                    ddlRentalDueDate.SelectedValue = recordItem["RentalDueDate"].ToString();

                }

                if (recordItem["GracePeriod"] != null)
                {
                    ddlGracePeriod.SelectedValue = recordItem["GracePeriod"].ToString();

                }
                if (recordItem["RenewalPeriod"] != null)
                {

                    string[] sRenewalArr = recordItem["RenewalPeriod"].ToString().Split('-');

                    txtRenewalYear.Text = sRenewalArr[0];
                    txtRenewalMonth.Text = sRenewalArr[1];
                    txtRenewalDay.Text = sRenewalArr[2];
                }

                if (recordItem["RenewalPeriod2"] != null)
                {

                    string[] sRenewalArr2 = recordItem["RenewalPeriod2"].ToString().Split('-');

                    txtRenewalYear2.Text = sRenewalArr2[0];
                    txtRenewalMonth2.Text = sRenewalArr2[1];
                    txtRenewalDay2.Text = sRenewalArr2[2];
                }

                if (recordItem["LicenseTerm"] != null)
                {
                    if (recordItem["LicenseTerm"].ToString() == "First")
                    {
                        rdoTerm1.Checked = true;
                    }
                    if (recordItem["LicenseTerm"].ToString() == "Second")
                    {
                        rdoTerm2.Checked = true;
                    }
                    if (recordItem["LicenseTerm"].ToString() == "Third")
                    {
                        rdoTerm3.Checked = true;
                    }
                }

                ////chkCash.Checked
                if (recordItem["SecurityDepositAmount"] != null)
                {
                    txtSecurityAmt.Text = recordItem["SecurityDepositAmount"].ToString();
                }
                if (recordItem["UtilitiesDepositAmount"] != null)
                {
                    txtUtilitiesDeposit.Text = recordItem["UtilitiesDepositAmount"].ToString();
                }
                if (recordItem["FittingOutDeposit"] != null)
                {
                    txtFittingDeposit.Text = recordItem["FittingOutDeposit"].ToString();
                }
                if (recordItem["UtilitiesFees"] != null)
                {
                    txtUtilitiesFees.Text = recordItem["UtilitiesFees"].ToString();
                }



                // chnages UAT 15/05/2017
                if (recordItem["SignageFees"] != null)
                {
                    txtSignageFees.Text = recordItem["SignageFees"].ToString();
                }

                if (recordItem["OtherFees1"] != null)
                {
                    ddlOtherFees1.SelectedItem.Text = recordItem["OtherFees1"].ToString();

                }

                if (recordItem["OtherFeesValue1"] != null)
                {
                    txtOtherFeesValue1.Text = recordItem["OtherFeesValue1"].ToString();

                }

                if (recordItem["OtherFees2"] != null)
                {
                    ddlOtherFees2.SelectedItem.Text = recordItem["OtherFees2"].ToString();
                }

                if (recordItem["OtherFeesValue2"] != null)
                {
                    txtOtherFeesValue2.Text = recordItem["OtherFeesValue2"].ToString();
                }

                // end 



                if (recordItem["StampDutyFilingDate"] != null)
                {
                    dtStampDutyDate.SelectedDate = Convert.ToDateTime(recordItem["StampDutyFilingDate"].ToString());
                }
                if (recordItem["FittingOutPeriodFrom"] != null)
                {
                    dtFittingFrom.SelectedDate = Convert.ToDateTime(recordItem["FittingOutPeriodFrom"].ToString());
                }
                if (recordItem["FittingOutPeriodTo"] != null)
                {
                    dtFittingTo.SelectedDate = Convert.ToDateTime(recordItem["FittingOutPeriodTo"].ToString());
                }
                //if (recordItem["PossessionDate"] != null)
                //{
                //    dtPossesionDate.SelectedDate = Convert.ToDateTime(recordItem["PossessionDate"].ToString());
                //}
                if (recordItem["HalalCertification"] != null)
                {
                    if (recordItem["HalalCertification"].ToString() == "True")
                    {
                        rdoHalalCertYes.Checked = true;
                    }
                    else
                    {
                        rdoHalalCertNo.Checked = true;
                    }
                }
                else
                {

                }



                if (recordItem["UtilityFixedVar"] != null)
                {

                    //	string strutilityfixedvar = recordItem["UtilityFixedVar"].ToString();

                    if (recordItem["UtilityFixedVar"].ToString() == "Direct")
                    {
                        rdodirectUtility.Checked = true;
                        rdoFixedUtility.Checked = false;
                        rdoVarUtility.Checked = false;
                        txtUtilitiesFees.Enabled = false;
                        txtUtilitiesFees.Text = "";
                    }

                    //ph2 end 


                    if (recordItem["UtilityFixedVar"].ToString() == "Yes")
                    {
                        rdoFixedUtility.Checked = true;
                        rdoVarUtility.Checked = false;
                        rdodirectUtility.Checked = false;    // ph2 direct billing
                        txtUtilitiesFees.Enabled = true;
                    }

                    if (recordItem["UtilityFixedVar"].ToString() == "Fixed")
                    {
                        rdoFixedUtility.Checked = true;
                        rdoVarUtility.Checked = false;
                        rdodirectUtility.Checked = false;    // ph2 direct billing
                        txtUtilitiesFees.Enabled = true;
                    }

                    if (recordItem["UtilityFixedVar"].ToString() == "No")
                    {
                        rdoFixedUtility.Checked = false;
                        rdoVarUtility.Checked = true;
                        rdodirectUtility.Checked = false;   // ph2 direct billing
                        txtUtilitiesFees.Enabled = false;
                        txtUtilitiesFees.Text = "";
                    }
                    if (recordItem["UtilityFixedVar"].ToString() == "Variable")
                    {
                        rdoFixedUtility.Checked = false;
                        rdoVarUtility.Checked = true;
                        rdodirectUtility.Checked = false;   // ph2 direct billing
                        txtUtilitiesFees.Enabled = false;
                        txtUtilitiesFees.Text = "";
                    }


                }


                // ph2 



                if (recordItem["ApprovalOfAward"] != null)
                {
                    lblApprovingAuthority.Text = recordItem["ApprovalOfAward"].ToString();
                }

                if (recordItem["TotalContractValue"] != null)
                {
                    txtContractValue.Text = recordItem["TotalContractValue"].ToString();
                }

                if (recordItem["ApprovalofAwardDate"] != null)
                {
                    dtApprovalDate.SelectedDate = Convert.ToDateTime(recordItem["ApprovalofAwardDate"].ToString());
                }

                if (recordItem["SuspensionDateFrom"] != null)
                {
                    dtSuspensionFrom.SelectedDate = Convert.ToDateTime(recordItem["SuspensionDateFrom"].ToString());
                }
                if (recordItem["SuspensionDateTo"] != null)
                {
                    dtSuspensionTo.SelectedDate = Convert.ToDateTime(recordItem["SuspensionDateTo"].ToString());
                }
                if (recordItem["EarlyTerminationDate"] != null)
                {
                    dtEarlyTerminationDate.SelectedDate = Convert.ToDateTime(recordItem["EarlyTerminationDate"].ToString());
                }
                if (recordItem["ReasonForEarlyTermination"] != null)
                {
                    txtReason.Text = recordItem["ReasonForEarlyTermination"].ToString();
                }
                if (recordItem["Remarks"] != null)
                {
                    txtRemarks.Text = recordItem["Remarks"].ToString();
                }

                //PH2 get previous tenency agreement number 

                if (recordItem["TenancyRecordNumberOld"] != null)
                {
                    lblPrevRecordNumber.Text = recordItem["TenancyRecordNumberOld"].ToString();
                }
                //end
                //calculate total tenure

                if (recordItem["totaltenuremonths"] != null)
                {
                    lbltotaltenuremonths.Text = recordItem["totaltenuremonths"].ToString();
                }

                if (recordItem["totaltenurevalue"] != null)
                {
                    lbltotaltenurevalue.Text = recordItem["totaltenurevalue"].ToString();
                }



                // end

                if (recordItem["AgreementStatus"] != null)
                {
                    drpAgreementStatus.SelectedValue = recordItem["AgreementStatus"].ToString();
                    drpAgreementStatus.SelectedItem.Text = recordItem["AgreementStatus"].ToString(); //ph2
                    drpAgreementStatus.Enabled = true;

                    //if user is a BDGroup member...
                    if (GetGroups(BDGroup))
                    {
                        //do nothing...
                    }
                    else
                    {
                        //if ((recordItem["AgreementStatus"].ToString() == "Draft") || (recordItem["AgreementStatus"].ToString() == "Pending for Approval"))
                        if ((recordItem["AgreementStatus"].ToString() == "Draft") || (recordItem["AgreementStatus"].ToString() == "Submit for Approval"))
                        {
                            drpAgreementStatus.Enabled = true;

                        }
                        //disbaled ph2	if (recordItem["AgreementStatus"].ToString() != "Pending for Approval")
                        //disbaled ph2	{
                        //disbaled ph2		drpAgreementStatus.Enabled = false;
                        //disbaled ph2	}
                    }
                }





            }
            //}

        }


        protected void FirstGridViewRow()
        {
            DataTable dt = new DataTable();
            DataRow dr = null;

            dt.Columns.Add(new DataColumn("Col1", typeof(DateTime)));
            dt.Columns.Add(new DataColumn("Col2", typeof(DateTime)));
            dt.Columns.Add(new DataColumn("Col3", typeof(string)));
            dt.Columns.Add(new DataColumn("Col4", typeof(string)));
            dt.Columns.Add(new DataColumn("Col5", typeof(string)));
            dt.Columns.Add(new DataColumn("Col6", typeof(string)));
            dt.Columns.Add(new DataColumn("Col7", typeof(string)));

            dr = dt.NewRow();
            dr["Col1"] = DateTime.Now.Date;
            dr["Col2"] = DateTime.Now.Date;
            dr["Col3"] = string.Empty;
            dr["Col4"] = string.Empty;
            dr["Col5"] = string.Empty;
            dr["Col6"] = string.Empty;
            dr["Col7"] = string.Empty;

            if (dt.Rows.Count <= 10)
            {
                dt.Rows.Add(dr);
            }
            ViewState["CurrentTable"] = dt;
            grvTenantDetails.DataSource = dt;
            grvTenantDetails.DataBind();
            DateTimeControl txn = (DateTimeControl)grvTenantDetails.Rows[0].Cells[1].FindControl("TenancyStartDate");
            DateTimeControl txn1 = (DateTimeControl)grvTenantDetails.Rows[0].Cells[2].FindControl("TenancyEndDate");
            TextBox txn2 = (TextBox)grvTenantDetails.Rows[0].Cells[3].FindControl("txtCompliance3");
            TextBox txn3 = (TextBox)grvTenantDetails.Rows[0].Cells[4].FindControl("txtCompliance4");
            Label txn4 = (Label)grvTenantDetails.Rows[0].Cells[5].FindControl("lblLicenseDetailID");
            Label txn5 = (Label)grvTenantDetails.Rows[0].Cells[6].FindControl("lblFirstRent");
            Label txn6 = (Label)grvTenantDetails.Rows[0].Cells[7].FindControl("lblLastRent");

            Button btnAdd = (Button)grvTenantDetails.HeaderRow.Cells[4].FindControl("ButtonAdd");
            //Page.Form.DefaultFocus = btnAdd.ClientID;

        }

        void bindLicenseGrid(int iAgreementID)
        {
            SPWeb web = site.OpenWeb();


            SPList LicenseList;

            // if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2 draft
            if (mRecord != "Draft") //ph2 draft
            {
                LicenseList = web.Lists[strTestTenantList];

            }
            else
            {
                LicenseList = web.Lists[strTestTenantListDraft];
            }


            SPQuery oLicQuery = new SPQuery();
            oLicQuery.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID' /><Value Type='Text'>" + iAgreementID.ToString() + "</Value></Eq></Where>";
            SPListItemCollection LicenseListCollection = LicenseList.GetItems(oLicQuery);

            if (LicenseListCollection.Count > 0)
            {
                AddToLogFile("bindLicenseGrid", LicenseListCollection.Count.ToString());
                DataTable dt = new DataTable();
                DataRow dr = null;

                dt.Columns.Add(new DataColumn("Col1", typeof(DateTime)));
                dt.Columns.Add(new DataColumn("Col2", typeof(DateTime)));
                dt.Columns.Add(new DataColumn("Col3", typeof(string)));
                dt.Columns.Add(new DataColumn("Col4", typeof(string)));
                dt.Columns.Add(new DataColumn("Col5", typeof(string)));
                dt.Columns.Add(new DataColumn("Col6", typeof(string)));
                dt.Columns.Add(new DataColumn("Col7", typeof(string)));

                for (int i = 0; i < LicenseListCollection.Count; i++)
                {
                    dr = dt.NewRow();
                    dr["Col1"] = DateTime.Now.Date;
                    dr["Col2"] = DateTime.Now.Date;
                    dr["Col3"] = string.Empty;
                    dr["Col4"] = string.Empty;
                    dr["Col5"] = string.Empty;
                    dr["Col6"] = string.Empty;
                    dr["Col7"] = string.Empty;
                    if (dt.Rows.Count <= 10)
                    {
                        dt.Rows.Add(dr);
                    }
                }

                ViewState["CurrentTable"] = dt;
                grvTenantDetails.DataSource = dt;
                grvTenantDetails.DataBind();

                int rows = 0;
                foreach (SPListItem LicItem in LicenseListCollection)
                {
                    for (int col = 0; col < grvTenantDetails.Rows[rows].Cells.Count; col++)
                    {
                        switch (col)
                        {
                            case 0:
                                //TextBox txn3 = (TextBox)grvTenantDetails.Rows[0].Cells[4].FindControl("txtCompliance4");
                                // grdCompliance.DataKeys[rows]["complianceID"] = item["ID"].ToString();
                                DateTimeControl txn = (DateTimeControl)grvTenantDetails.Rows[rows].Cells[col].FindControl("TenancyStartDate");
                                if (LicItem["LicenseStartDate"] != null)
                                {
                                    txn.SelectedDate = Convert.ToDateTime(LicItem["LicenseStartDate"].ToString());
                                }
                                break;
                            case 1:
                                DateTimeControl txn1 = (DateTimeControl)grvTenantDetails.Rows[rows].Cells[col].FindControl("TenancyEndDate");
                                if (LicItem["LicenseEndDate"] != null)
                                {
                                    txn1.SelectedDate = Convert.ToDateTime(LicItem["LicenseEndDate"].ToString());
                                }
                                break;

                            case 2:
                                TextBox txtCompliance2 = (TextBox)grvTenantDetails.Rows[rows].Cells[col].FindControl("txtCompliance3");
                                if (LicItem["MonthlyRent"] != null)
                                {
                                    txtCompliance2.Text = LicItem["MonthlyRent"].ToString();
                                }
                                break;

                            case 3:
                                TextBox txtCompliance3 = (TextBox)grvTenantDetails.Rows[rows].Cells[col].FindControl("txtCompliance4");
                                if (LicItem["RentPSF"] != null)
                                {
                                    txtCompliance3.Text = LicItem["RentPSF"].ToString();
                                }
                                break;

                            case 4:
                                Label lblLicense = (Label)grvTenantDetails.Rows[rows].Cells[col].FindControl("lblLicenseDetailID");
                                lblLicense.Text = LicItem["ID"].ToString();
                                break;

                            case 5:
                                Label lblFirstR = (Label)grvTenantDetails.Rows[rows].Cells[col].FindControl("lblFirstRent");
                                lblFirstR.Text = LicItem["NetFirstRent"].ToString();
                                break;

                            case 6:
                                Label lblLastR = (Label)grvTenantDetails.Rows[rows].Cells[col].FindControl("lblLastRent");
                                lblLastR.Text = LicItem["NetLastRent"].ToString();
                                break;


                        }
                    }
                    rows++;
                }
            }
            else
            {
                FirstGridViewRow();
            }

            //place new code here...
            int iDays = 0;
            double dMonthlyRent = 0.00;
            // ph2 
            double dMonthlyRentLbl1 = 0.00;
            double dMonthlyRentLbl2 = 0.00;
            double dMonthlyRentLbl3 = 0.00;
            double dMonthlyRentLbl4 = 0.00;
            double dMonthlyRentLbl5 = 0.00;
            double dMonthlyRentLbl6 = 0.00;
            double dMonthlyRentLbl7 = 0.00;

            //end ph2
            int iLastRow = grvTenantDetails.Rows.Count - 1;

            //first payment logic...
            DateTimeControl dSD = (DateTimeControl)grvTenantDetails.Rows[0].Cells[1].FindControl("TenancyStartDate");
            TextBox tMonthlyRent = (TextBox)grvTenantDetails.Rows[0].Cells[3].FindControl("txtCompliance3");
            if (tMonthlyRent.Text.Trim() != "")
            {
                dMonthlyRent = Convert.ToDouble(tMonthlyRent.Text);
            }

            //ph2 


            if (txtSecurityAmt.Text.Trim() != "")
            {
                dMonthlyRentLbl1 = Convert.ToDouble(txtSecurityAmt.Text);
            }

            if (txtUtilitiesDeposit.Text.Trim() != "")
            {
                dMonthlyRentLbl2 = Convert.ToDouble(txtUtilitiesDeposit.Text);
            }

            if (txtFittingDeposit.Text.Trim() != "")
            {
                dMonthlyRentLbl3 = Convert.ToDouble(txtFittingDeposit.Text);
            }

            if (txtServiceChgs.Text.Trim() != "")
            {
                dMonthlyRentLbl4 = Convert.ToDouble(txtServiceChgs.Text);
            }

            if (txtUtilitiesFees.Text.Trim() != "")
            {
                dMonthlyRentLbl5 = Convert.ToDouble(txtUtilitiesFees.Text);
            }

            if (txtSignageFees.Text.Trim() != "")
            {
                dMonthlyRentLbl6 = Convert.ToDouble(txtSignageFees.Text);
            }


            if (txtOtherFeesValue1.Text.Trim() != "")
            {
                dMonthlyRentLbl7 = Convert.ToDouble(txtOtherFeesValue1.Text);
            }




            //	if (ddlOtherFees1.SelectedItem.Text != "Select Other Fee")
            //	{
            //		dMonthlyRentLbl7 = Convert.ToDouble(ddlOtherFees1.SelectedItem.Text);
            //	}



            //end


            iDays = DateTime.DaysInMonth(dSD.SelectedDate.Year, dSD.SelectedDate.Month);
            if (dSD.SelectedDate.Day != 1)
            {
                int iBalDays = iDays - dSD.SelectedDate.Day + 1;
                double dBalanceDays = (double)iBalDays / (double)iDays;
                lblFirstRentNotes.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRent, 2) + ". ";
                lblFirstMonthlyRent1.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl1, 2) + ". ";
                lblFirstMonthlyRent2.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl2, 2) + ". ";
                lblFirstMonthlyRent3.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl3, 2) + ". ";
                lblFirstMonthlyRent4.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl4, 2) + ". ";
                lblFirstMonthlyRent5.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl5, 2) + ". ";
                lblFirstMonthlyRent6.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl6, 2) + ". ";
                lblFirstMonthlyRent7.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl7, 2) + ". ";
            }

            //last payment logic...
            DateTimeControl dED = (DateTimeControl)grvTenantDetails.Rows[iLastRow].Cells[2].FindControl("TenancyEndDate");
            tMonthlyRent = (TextBox)grvTenantDetails.Rows[iLastRow].Cells[3].FindControl("txtCompliance3");
            dMonthlyRent = 0.00;
            if (tMonthlyRent.Text != "")
            {
                dMonthlyRent = Convert.ToDouble(tMonthlyRent.Text);
            }

            iDays = DateTime.DaysInMonth(dED.SelectedDate.Year, dED.SelectedDate.Month);
            if (dED.SelectedDate.Day != iDays)
            {
                int iBalDays = dED.SelectedDate.Day;
                double dBalanceDays = (double)iBalDays / (double)iDays;
                lblLastRentNotes.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRent, 2) + ". ";
                lblLastMonthlyRent1.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl1, 2) + ". ";

                lblLastMonthlyRent2.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl2, 2) + ". ";
                lblLastMonthlyRent3.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl3, 2) + ". ";
                lblLastMonthlyRent4.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl4, 2) + ". ";
                lblLastMonthlyRent5.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl5, 2) + ". ";
                lblLastMonthlyRent6.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl6, 2) + ". ";
                lblLastMonthlyRent7.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl7, 2) + ". ";

            }

        }





        /// <summary>
        /// Binding CCNames from the CommunityClub List. We are getting All the CCName from the Community Club List
        /// </summary>
        public void bindCCName()
        {
            bool bCCData = false;
            int iGroupCount = 0;
            using (SPWeb web = site.OpenWeb())
            {
                SPList CommunityClubList = web.Lists[strCommunityClubListName];

                if (CommunityClubList.Items.Count > 0)
                {
                    foreach (SPListItem item in CommunityClubList.Items)
                    {
                        //for BDGroup...
                        if (SPContext.Current.Web.SiteGroups[BDGroup].ContainsCurrentUser)
                        {
                            bCCData = true;
                            ddlCCName.Items.Add(new ListItem(item["CCName"].ToString(), item["ID"].ToString()));
                        }
                        else
                        {
                            //iGroupCount = 0;
                            string sGroup = item["CCName"].ToString().ToUpper() + " Group";
                            if (fGroupExists(web, sGroup))                                  //chk group existence...
                            {
                                //iGroupCount = 1;
                                //if (CheckIfGroupExistsBasedOnName(SPContext.Current.Web.SiteGroups, sGroup))
                                //chk if user exists in the group...
                                SPUser user = SPContext.Current.Web.CurrentUser;
                                SPGroupCollection oUserGroupColl = user.Groups;
                                if (oUserGroupColl.Count > 0)
                                {
                                    //SPGroup oUserGroup = oUserGroupColl[sGroup];
                                    //if (oUserGroup != null)
                                    if (SPContext.Current.Web.SiteGroups[sGroup].ContainsCurrentUser)
                                    {
                                        //iGroupCount = 1;
                                        bCCData = true;
                                        ddlCCName.Items.Add(new ListItem(item["CCName"].ToString(), item["ID"].ToString()));
                                    }
                                }

                            }
                            else
                            {
                                continue;
                            }
                        }
                    }
                }
                else
                {
                    bCCData = false;
                    this.Page.RegisterStartupScript("AlertMsg", "<script type='text/javascript'>alert('No Community Clubs or PA Divisions are available.');</script>");
                }


                if (!bCCData)
                {
                    this.Page.RegisterStartupScript("AlertMsg", "<script type='text/javascript'>alert('No Groups are assigned to you. Please contact site administrator.');</script>");
                }

            }

        }


        //start function

        // added by sk ph2 
        // Binding Company name (Tenant Names) from the Tenant Master List. We are getting All the company names from the Tenant Master List

        // start

        public void bindCompanyName()
        {
            //	ddlCCName.Items.Add(new ListItem("Select Company Name", "000"));  bug fix 04th May 2017

            // ddlTenantName.Items.Add(new ListItem("Select Company Name", "000"));

            using (SPWeb web = site.OpenWeb())
            {
                SPList TCode = web.Lists[strTenantMasterListName];
                foreach (SPListItem TCodeNo in TCode.Items)
                {
                    ddlTenantName.Items.Add(new ListItem(TCodeNo["TenantName"].ToString(), TCodeNo["ID"].ToString()));
                }
            }
        }

        public void bindOtherFees()
        {
            ddlOtherFees1.Items.Add(new ListItem("Select Other Fee", "000"));
            ddlOtherFees2.Items.Add(new ListItem("Select Other Fee", "000"));

            //	ddlOtherFees.Items.Add("Select Other Fee");

            using (SPWeb web = site.OpenWeb())
            {
                SPList TCode = web.Lists[strGeneralSettings];
                foreach (SPListItem TCodeNo in TCode.Items)
                {
                    String strkeyword = "";
                    string stractive = "";

                    if (TCodeNo["Category"].ToString() != null)
                    {
                        strkeyword = TCodeNo["Category"].ToString();
                    }

                    if (strkeyword == "OtherFeeOptions")
                    {
                        if (TCodeNo["Active"].ToString() != null)
                        {
                            stractive = TCodeNo["Active"].ToString();
                        }
                    }
                    if ((strkeyword == "OtherFeeOptions") && (stractive == "True"))
                    {

                        ddlOtherFees1.Items.Add(new ListItem(TCodeNo["ConfigValue"].ToString(), TCodeNo["ID"].ToString()));
                        ddlOtherFees2.Items.Add(new ListItem(TCodeNo["ConfigValue"].ToString(), TCodeNo["ID"].ToString()));


                    }
                }
            }
        }
        //end fnction

        private static bool fGroupExists(SPWeb _Web, string name)
        {
            SPGroup currentGroup = null;
            try
            {
                currentGroup = _Web.SiteGroups[name];
                return true;
            }
            catch
            {
                return false;

            }

            //return currentGroup;
        }

        private static bool CheckIfGroupExistsBasedOnName(SPGroupCollection collection, string name)
        {

            if (string.IsNullOrEmpty(name) || (name.Length > 255) || (collection == null) || (collection.Count == 0))
            {
                return false;
            }
            else
            {
                return (collection.GetCollection(new string[] { name }).Count > 0);
            }
        }


        protected void dtApprovalDate_OnDateChanged(object sender, EventArgs e)
        {
            this.Page.ClientScript.RegisterStartupScript(this.GetType(), "AlertMsg", "fUpdateAppAuthority();", true);
        }


        protected void ddlCCName_SelectedIndexChanged(object sender, EventArgs e)
        {
            lblErrorMsg.Text = "";
            string CCGroup = ddlCCName.SelectedItem.Text + " " + "Group";
            //check whether the group exists or not...

            //		if ((SPContext.Current.Web.SiteGroups[BDGroup].ContainsCurrentUser) || (SPContext.Current.Web.SiteGroups[CCGroup].ContainsCurrentUser))
            //		{
            try
            {
                DropDownList ddlSelected = (DropDownList)sender;
                int iSelectedID = Convert.ToInt32(ddlSelected.SelectedValue);
                using (SPWeb web = site.OpenWeb())
                {
                    SPList UnitInfoList = web.Lists[strUnitInformationList];
                    SPQuery query = new SPQuery();
                    SPQuery query1 = new SPQuery();
                    //show only Available units..
                    if (!bEdit)
                    {
                        query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Available</Value></Eq></And></Where>";
                        query1.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Tenanted</Value></Eq></And></Where>";
                    }
                    else
                    {
                        //	if (mRecord == "Draft") {


                        query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Or><Eq><FieldRef Name='Status' /><Value Type='Text'>Available</Value></Eq><Or><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Tenanted</Value></Eq></Or></Or></And></Where>";
                        query1.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Tenanted</Value></Eq></And></Where>";
                        /*
                        // DISBALE UAT START
                        if ((sTenancyRecordType == "Renewal") || (sAgreementCategory == "Novation"))
                        {
                            query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Or><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Tenanted</Value></Eq></Or></And></Where>";
                        } 
                        else if 
                         (mRecord == "Draft") {

                            //query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq></And></Where>";
                        //query.Query = "<Where><Or><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Available</Value></Eq></Or><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq></And></Where>";
                        //query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Or><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Available</Value></Eq></Or></And></Where>";
                    //	query.Query = "<Where><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq></Where>"; DISBALE 

                        query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Available</Value></Eq></And></Where>"; // ENABLE FOR EDIT MODE
                        }

                        else {

                        //	query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq></And></Where>"; // ENABLE FOR EDIT MODE
                        //	query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Available</Value></Eq></And></Where>"; // ENABLE FOR EDIT MODE
                            query.Query = "<Where><And><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq><Or><Eq><FieldRef Name='Status' /><Value Type='Text'>Committed</Value></Eq><Eq><FieldRef Name='Status' /><Value Type='Text'>Tenanted</Value></Eq></Or></And></Where>";
                        }
                        */
                        // DISBALE UAT END

                    }

                    //ddlUnitNumber.Items.Clear();
                    lbxUnitNumber.Items.Clear();
                    //query.Query = "<Where><Eq><FieldRef Name='CClubID' /><Value Type='Number'>" + iSelectedID.ToString() + "</Value></Eq></Where>";
                    SPListItemCollection myItem = UnitInfoList.GetItems(query);
                    SPListItemCollection myOldItems = UnitInfoList.GetItems(query1);
                    DateTime oLastEndDate;
                    if (myItem.Count > 0)
                    {
                        foreach (SPListItem UnitItem in myItem)
                        {
                            //ddlUnitNumber.Items.Add(new ListItem(UnitItem["Floor"].ToString(), UnitItem["ID"].ToString()));
                            lbxUnitNumber.Items.Add(new ListItem(UnitItem["Floor"].ToString(), UnitItem["ID"].ToString()));
                        }
                    }

                    if (myOldItems.Count > 0)
                    {
                        foreach (SPListItem oUnitItem in myOldItems)
                        {
                            if (oUnitItem["LastLicenseEndDate"] != null)
                            {
                                if (oUnitItem["LastLicenseEndDate"].ToString() != string.Empty)
                                {
                                    oLastEndDate = (DateTime)oUnitItem["LastLicenseEndDate"];
                                    TimeSpan tSpan = oLastEndDate.Subtract(DateTime.Now.Date);
                                    if (tSpan.Days <= 365)
                                    {
                                        lbxUnitNumber.Items.Add(new ListItem(oUnitItem["Floor"].ToString(), oUnitItem["ID"].ToString()));
                                    }
                                }
                            }
                        }

                    }

                    if (myItem.Count == 0 & myOldItems.Count == 0)
                    {
                        if (mRecord != "Draft")
                        {
                            // this.Page.RegisterStartupScript("AlertMSg", "<script type='text/javascript'>alert('The selected CC does not have any units.');</script>");
                            //lblErrorMsg.Text = "The Selected CC does not have any Units.";
                            AddToLogFile("CCName_IndexChangeEvent", "Units in selected CC are not available");
                        }

                    }

                }
            }
            catch (Exception ex)
            {
                AddToLogFile("CCName Index changing In UnitInfo Form:", ex.Message);
            }
            //		}
            //		else
            //		{
            //			this.Page.RegisterStartupScript("AlertMessage", "<script type='text/javascript'>alert('Error. You do not have sufficient permissions to view this CC Data. Please contact the System Administrator.');location.href='../default.aspx';</script>");
            //		}
        }


        //added by SK COMPANY/TENANT NAME SELECTED AUTO POPULATE FROM TENANT MASTER - PH2

        protected void ddlOtherFees_SelectedIndexChanged(object sender, EventArgs e)
        {
            DropDownList ddlSelected = (DropDownList)sender;
            int iSelectedID = Convert.ToInt32(ddlOtherFees1.SelectedValue);
            GetCCDataO(iSelectedID);

        }

        void GetCCDataO(int iSelRecord)
        {
            try
            {
                // if (SPContext.Current.Web.SiteGroups[BDGroup].ContainsCurrentUser)
                // {
                using (SPWeb web = site.OpenWeb())
                {
                    SPList TCode = web.Lists[strGeneralSettings];
                    SPListItem selectedItem = TCode.Items.GetItemById(iSelRecord);

                    if (selectedItem["OtherfeeAmount"] != null)
                    {
                        //	txtOtherFees.Text = selectedItem["OtherfeeAmount"].ToString();

                    }

                }

            }
            catch (Exception ex)
            {
                AddToLogFile("other fee Dropdown Index changing In Tenancy agreement Form:", ex.Message);
            }
        }

        // END


        protected void ddlTenantName_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddlTenantName.SelectedValue != "Select Company Name")
            {
                DropDownList ddlSelected = (DropDownList)sender;
                int iSelectedID = Convert.ToInt32(ddlSelected.SelectedValue);
                GetCCData(iSelectedID);
            }
            if (ddlTenantName.SelectedValue == "Select Company Name")
            {
                txtROCNumber.Text = "";
                txtCompanyType.Text = "";
                txtRegisteredAdd.Text = "";
            }

        }

        void GetCCData(int iSelRecord)
        {
            try
            {
                // if (SPContext.Current.Web.SiteGroups[BDGroup].ContainsCurrentUser)
                // {
                using (SPWeb web = site.OpenWeb())
                {
                    SPList TCode = web.Lists[strTenantMasterListName];
                    SPListItem selectedItem = TCode.Items.GetItemById(iSelRecord);

                    if (selectedItem["TenantName"] != null)
                    {
                        // txtTenantName.Text = selectedItem["TenantName"].ToString();
                    }

                    if (selectedItem["ROCUEN"] != null)
                    {
                        txtROCNumber.Text = selectedItem["ROCUEN"].ToString();
                    }
                    if (selectedItem["TypeOfCompany"] != null)
                    {
                        txtCompanyType.Text = selectedItem["TypeOfCompany"].ToString();
                    }

                    if (selectedItem["RegisteredAddress"] != null)
                    {
                        txtRegisteredAdd.Text = selectedItem["RegisteredAddress"].ToString();
                    }
                }

            }
            catch (Exception ex)
            {
                AddToLogFile("Company Name / Tenant Name Dropdown Index changing In Tenancy agreement Form:", ex.Message);
            }
        }
        //END SK 









        /// <summary>
        /// Binding All Districts from DistrictList
        /// </summary>
        public void bindTradeCategory()
        {
            ddlTradeCat.Items.Add(new ListItem("Select Trade Category"));
            using (SPWeb web = site.OpenWeb())
            {
                SPList TClist = web.Lists[strTradeCategoryList];
                foreach (SPListItem Item in TClist.Items)
                {
                    ddlTradeCat.Items.Add(new ListItem(Item["Title"].ToString()));
                }
            }
        }




        protected void rdoUnitOption1_CheckedChanged(object sender, EventArgs args)
        {

            RadioButton chkItem = sender as RadioButton;
            Boolean itemState = chkItem.Checked;

            if (itemState)
            {
                lblSQFT.Text = "";
                lblSQMT.Text = "";
                lbxUnitNumber.SelectionMode = ListSelectionMode.Single;
            }


        }

        protected void rdoUnitOption2_CheckedChanged(object sender, EventArgs args)
        {

            RadioButton chkItem = sender as RadioButton;
            Boolean itemState = chkItem.Checked;

            if (itemState)
            {
                lblSQFT.Text = "";
                lblSQMT.Text = "";
                lbxUnitNumber.SelectionMode = ListSelectionMode.Multiple;
            }
        }


        protected void btnGetSQFT_Click(object sender, EventArgs e)
        {

            double dSQFT = 0.00;
            try
            {
                int iSelectedID = 0;

                using (SPWeb web = site.OpenWeb())
                {
                    // GetSelectedIndices
                    foreach (int i in lbxUnitNumber.GetSelectedIndices())
                    {
                        SPList UnitInfoList = web.Lists[strUnitInformationList];
                        iSelectedID = Convert.ToInt16(lbxUnitNumber.Items[i].Value);

                        SPListItem unitItem = UnitInfoList.GetItemById(iSelectedID);
                        if (unitItem["SquareFeet"] != null)
                        {
                            if (unitItem["SquareFeet"].ToString().Trim() != "")
                            {
                                dSQFT = dSQFT + Convert.ToDouble(unitItem["SquareFeet"].ToString());
                            }
                        }
                        else
                        {
                            dSQFT = dSQFT + 0.00;
                        }

                    }
                }

                lblSQFT.Text = dSQFT.ToString();

                double dCalSQMT = Math.Round((dSQFT / 10.7639104), 2);
                lblSQMT.Text = dCalSQMT.ToString();


                for (int trow = 0; trow < grvTenantDetails.Rows.Count; trow++)
                {
                    GridViewRow currentRow = grvTenantDetails.Rows[trow];
                    int rowindex = 0;
                    rowindex = currentRow.RowIndex;
                    TextBox oMonthlyRent = (TextBox)currentRow.Cells[3].FindControl("txtCompliance3");
                    if (oMonthlyRent.Text.Trim() != "")
                    {

                        double dRent = Math.Round(Convert.ToDouble(oMonthlyRent.Text) / dSQFT, 2);
                        TextBox oText2 = (TextBox)currentRow.Cells[3].FindControl("txtCompliance4");
                        oText2.Text = dRent.ToString();
                    }
                }
            }
            catch (Exception ex)
            {
                lblErrorMsg.Text = ex.Message;
                AddToLogFile("Unit Number Index changing In Tenancy Agreement Form:", ex.Message);
            }
        }

        protected void TenureValidation(object source, ServerValidateEventArgs args)
        {
            args.IsValid = txtTenureYear.Text.Trim().Length > 0 || txtTenureMonth.Text.Trim().Length > 0 || txtTenureDay.Text.Trim().Length > 0;
        }

        protected void RenewalValidation(object source, ServerValidateEventArgs args)
        {
            args.IsValid = txtRenewalYear.Text.Trim().Length > 0 || txtRenewalMonth.Text.Trim().Length > 0 || txtRenewalDay.Text.Trim().Length > 0;
        }


        /// <summary>
        /// Generate Tenancy Record Number...this is a unique number assigned to each Tenancy Agreement 
        /// </summary>
        public void genTenancyRecordNumber(string mode)
        {
            String sDate = DateTime.Today.Date.ToString("yyyyMM");

            //ph2 chnages
            String sPrefix = "";

            if (mode == "Draft")
            {
                sPrefix = "Draft";
            }

            if (mode == "TMS")
            {
                sPrefix = "TMS";
            }

            int iLastAppNo;

            using (SPWeb web = site.OpenWeb())
            {
                string strNewApplicationNo = string.Empty;
                SPList appFYMMlist = web.Lists["ApplicationSettings"];
                SPQuery queryFYMMlist = new SPQuery();

                //ph2 

                // if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2
                if (mode != "Draft") //ph2
                {
                    queryFYMMlist.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "LastAgreementNumber");
                }
                else
                {
                    queryFYMMlist.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "DraftAgreementNumber");
                }
                //end ph2



                SPListItemCollection col = appFYMMlist.GetItems(queryFYMMlist);

                if (col.Count == 1)
                {
                    SPListItem item = col[0];
                    iLastAppNo = Convert.ToInt32(item["Value"].ToString());
                    iLastAppNo = iLastAppNo + 1;
                }
                else
                {
                    iLastAppNo = 999;
                }

                strNewApplicationNo = iLastAppNo.ToString();

                if (strNewApplicationNo.Length == 1) { strNewApplicationNo = "000" + strNewApplicationNo; }
                else if (strNewApplicationNo.Length == 2) { strNewApplicationNo = "00" + strNewApplicationNo; }
                else if (strNewApplicationNo.Length == 3) { strNewApplicationNo = "0" + strNewApplicationNo; }


                lblRecordNumber.Text = sPrefix + "-" + sDate + "-" + strNewApplicationNo;
            }
        }

        //end 


        // update update tenancy record number

        public void updateTenancyRecordNumber(string mode)
        {
            SPWeb web;
            web = site.OpenWeb();
            SPList appSettings = web.Lists["ApplicationSettings"];
            SPQuery querySet = new SPQuery();

            //ph2 
            // SPQuery queryFYMMlist = new SPQuery();

            //	if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2
            if (mode != "Draft")
            {
                querySet.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "LastAgreementNumber");
            }
            else
            {
                querySet.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "DraftAgreementNumber");
            }



            //	querySet.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "LastAgreementNumber");


            SPListItemCollection aCol = appSettings.GetItems(querySet);

            if (aCol.Count > 0)
            {
                SPListItem oItem;

                if (mode != "Draft")
                {
                    oItem = aCol[0];
                }
                else
                {
                    oItem = aCol[0];
                }



                string[] sRecordCount = lblRecordNumber.Text.Split(new string[] { "-" }, StringSplitOptions.None);
                if (sRecordCount.Length > 0)
                {
                    oItem["Value"] = sRecordCount[2];
                }
                else
                {
                    oItem["Value"] = "9999";
                }
                oItem.Web.AllowUnsafeUpdates = true;
                oItem.Update();
            }

        }


        //end

        public static void AddToLogFile(string methodName, string Error)
        {
            SPSecurity.RunWithElevatedPrivileges(delegate ()
            {
                string LogPath = @"c:\TMS_LogFiles\";
                string filename = "TMS_Log_" + DateTime.Now.ToString("dd-MM-yyyy") + ".txt";
                string filepath = LogPath + filename;
                if (File.Exists(filepath))
                {
                    using (StreamWriter writer = new StreamWriter(filepath, true))
                    {
                        writer.WriteLine(DateTime.Now + ", " + "CreateTask , " + methodName + " , " + Error);
                    }
                }
                else
                {
                    StreamWriter writer = File.CreateText(filepath);
                    writer.WriteLine(DateTime.Now + ", " + "CreateTask , " + methodName + " , " + Error);
                    writer.Close();
                }
            });
        }

        protected void btnCancel_Click(object sender, EventArgs e)
        {
            Response.Redirect("..\\default.aspx");
        }



        protected void btnSave_Click(object sender, EventArgs e)
        {


            lblTest.Text = "";

            string sDate1 = DateTime.Today.Date.ToString("dd/MM/yyyy");
            lblErrorMsg.Text = "";
            Regex rTelCheck = new Regex("^[0-9]+$");
            Regex rAmount = new Regex("^[0-9]+([.,][0-9]{1,2})?$");

            //if (drpAgreementStatus.SelectedItem.Text == "Submit For Approval")
            //{
            //	drpAgreementStatus.SelectedItem.Text = "Pending For Approval";
            //	}


            if (drpAgreementStatus.SelectedItem.Text == "Draft")
            {
                lblTest.Text = "Please select Submit for approval";

                return;

            }
            if (drpAgreementStatus.SelectedItem.Text == "Pending for Approval")
            {
                lblTest.Text = "Please select Agreement Status";
                lblErrorMsg.Text = "Please select Agreement Status";

                return;

            }

            try
            {
                SPWeb web = null;

                int iProcess = 0;

                SPSecurity.RunWithElevatedPrivileges(delegate ()
                {
                    web = site.OpenWeb();
                    Page.Validate();
                    // new table 
                    bool bRowCount = false;
                    if (grvMonthlyRent.Rows.Count > 0)
                    {
                        bRowCount = true;
                    }


                    if (!bRowCount)
                    {
                        lblErrorMsg.Text = "License Details cannot be empty.";
                        return;
                    }
                });

                if (Page.IsValid)
                {
                    //ph2
                    //validations								




                    // ph2 chnages chnage new number

                    string recordno = lblRecordNumber.Text;
                    string subrecordno = recordno.Substring(0, 5);
                    string dflag = "";
                    if (subrecordno == "Draft")
                    {
                        dflag = "Yes";
                    }



                    if (!bEdit)
                    {

                        /*

                        if ((drpAgreementStatus.SelectedItem.Text != "Draft") && (mRecord == "Draft"))
                        {
                            lblTest.Text = "Please select Status as Draft";

                            return;

                        }

                        if (drpAgreementStatus.SelectedItem.Text != "Draft")					
                        {
                            lblTest.Text = "Please Save as a Draft and Review prior to submission";

                            return;

                        }

                        */

                        // TAList = web.Lists[strAgreementListNameDraft];
                        //	Item = TAList.Items.Add(); // for new documents

                        /*
                        if ((drpAgreementStatus.SelectedItem.Text == "Pending for Approval") && (dflag == "Yes"))
                           {						
                         //   string mode = "TMS";
                        //	genTenancyRecordNumber(mode);
                        //	updateTenancyRecordNumber(mode);
                           }

                          */
                        //end ph2

                    }
                    else
                    {

                        if (!ValidateLicenseDates())
                        {
                            return;
                        }


                        web = site.OpenWeb();
                        SPList TAList;
                        SPListItem Item;


                        // if ((drpAgreementStatus.SelectedItem.Text == "Pending for Approval") && (mRecord == "Draft") && (dflag == "Yes"))
                        if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft") && (dflag == "Yes"))
                        {
                            TAList = web.Lists[strAgreementListName];
                            Item = TAList.Items.Add();
                            //	string mode = "TMS";
                            //	genTenancyRecordNumber(mode);
                            //	updateTenancyRecordNumber(mode);


                        }
                        else
                        {
                            TAList = web.Lists[strAgreementListName];
                            Item = TAList.GetItemById(iRecord);
                        }




                        UpdateAuditTrail("CCName", ddlCCName.SelectedValue, Item, Item.Fields.GetFieldByInternalName("CCName"));
                        //	Item["CCName"] = ddlCCName.SelectedValue;
                        //	iCCID = Convert.ToInt32(ddlCCName.SelectedValue);

                        //ph2 draft
                        if (ddlCCName.SelectedItem.Text == "Select CC Name") // ph2 for draft
                        {
                            Item["CCName"] = "000";

                            iCCID = 000;
                        }
                        else
                        {
                            Item["CCName"] = ddlCCName.SelectedValue;

                            iCCID = Convert.ToInt32(ddlCCName.SelectedValue);
                        }

                        //end ph2

                        UpdateAuditTrail("AgreementStatus", drpAgreementStatus.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("AgreementStatus"));
                        Item["AgreementStatus"] = drpAgreementStatus.SelectedItem.Text;

                        //ph2 update resubmission date

                        if (drpAgreementStatus.SelectedItem.Text == "ReSubmission")
                        {
                            UpdateAuditTrail("ResubmissionDate", sDate1, Item, Item.Fields.GetFieldByInternalName("ResubmissionDate"));

                            Item["ResubmissionDate"] = DateTime.Today.Date;


                        }

                        //end ph2

                        UpdateAuditTrail("ApprovalOfAward", lblApprovingAuthority.Text, Item, Item.Fields.GetFieldByInternalName("ApprovalOfAward"));
                        Item["ApprovalOfAward"] = lblApprovingAuthority.Text;

                        if (txtContractValue.Text.Trim() != "")
                        {
                            //	if (rAmount.IsMatch(txtContractValue.Text.Trim()))
                            //	{
                            UpdateAuditTrail("TotalContractValue", txtContractValue.Text, Item, Item.Fields.GetFieldByInternalName("TotalContractValue"));
                            Item["TotalContractValue"] = Convert.ToDouble(txtContractValue.Text);
                            //	}
                            //	else
                            //	{
                            //	lblErrorMsg.Text = "Total Contract Value field should contain only numbers.";
                            //	return;
                            // }
                        }
                        else
                        {
                            Item["TotalContractValue"] = "0.00";
                        }



                        if (lbltotaltenuremonths.Text.Trim() != "")
                        {
                            UpdateAuditTrail("totaltenuremonths", lbltotaltenuremonths.Text, Item, Item.Fields.GetFieldByInternalName("totaltenuremonths"));
                            Item["totaltenuremonths"] = Convert.ToDouble(lbltotaltenuremonths.Text);


                        }
                        else
                        {
                            Item["totaltenuremonths"] = "0.00";
                        }
                        if (lbltotaltenurevalue.Text.Trim() != "")
                        {
                            UpdateAuditTrail("totaltenurevalue", lbltotaltenurevalue.Text, Item, Item.Fields.GetFieldByInternalName("totaltenurevalue"));
                            Item["totaltenurevalue"] = Convert.ToDouble(lbltotaltenurevalue.Text);


                        }
                        else
                        {
                            Item["totaltenurevalue"] = "0.00";
                        }

                        // renewal last row update to carry

                        if (lblRenewalMonthlyRent.Text != "")
                        {
                            UpdateAuditTrail("RenewalMonthlyRent", lblRenewalMonthlyRent.Text, Item, Item.Fields.GetFieldByInternalName("RenewalMonthlyRent"));
                            Item["RenewalMonthlyRent"] = lblRenewalMonthlyRent.Text;


                        }
                        else
                        {
                            Item["RenewalMonthlyRent"] = "0.00";
                        }


                        //end ph2

                        UpdateAuditTrail("ApprovalofAwardDate", dtApprovalDate.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("ApprovalofAwardDate"));
                        Item["ApprovalofAwardDate"] = dtApprovalDate.SelectedDate;

                        //sunil...
                        string sSelectedUnits = "";
                        foreach (int i in lbxUnitNumber.GetSelectedIndices())
                        {
                            sSelectedUnits = sSelectedUnits + lbxUnitNumber.Items[i].Value + ",";
                        }
                        UpdateAuditTrail("CCUnitNumber", sSelectedUnits, Item, Item.Fields.GetFieldByInternalName("CCUnitNumber"));
                        Item["CCUnitNumber"] = sSelectedUnits;

                        if (!dtEarlyTerminationDate.IsDateEmpty)
                        {
                            UpdateAuditTrail("EarlyTerminationDate", dtEarlyTerminationDate.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("EarlyTerminationDate"));
                            Item["EarlyTerminationDate"] = dtEarlyTerminationDate.SelectedDate;
                        }
                        else
                        {
                            UpdateAuditTrail("EarlyTerminationDate", "", Item, Item.Fields.GetFieldByInternalName("EarlyTerminationDate"));
                            Item["EarlyTerminationDate"] = null;
                        }

                        if (txtEmail.Text.Trim() != "")
                        {
                            if (IsValidEmail(txtEmail.Text.Trim()))
                            {
                                UpdateAuditTrail("EmailAddress", txtEmail.Text, Item, Item.Fields.GetFieldByInternalName("EmailAddress"));
                                Item["EmailAddress"] = txtEmail.Text;
                            }
                            else
                            {
                                lblErrorMsg.Text = "Email Address is not in correct format.";
                                return;
                            }
                        }

                        if (txtFittingDeposit.Text.Trim() != "")
                        {
                            if (rAmount.IsMatch(txtFittingDeposit.Text.Trim()))
                            {
                                UpdateAuditTrail("FittingOutDeposit", txtFittingDeposit.Text, Item, Item.Fields.GetFieldByInternalName("FittingOutDeposit"));
                                Item["FittingOutDeposit"] = Convert.ToDouble(txtFittingDeposit.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Fitting Out Deposit field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["FittingOutDeposit"] = "0.00";
                        }


                        if (!dtFittingFrom.IsDateEmpty)
                        {
                            UpdateAuditTrail("FittingOutPeriodFrom", dtFittingFrom.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodFrom"));
                            Item["FittingOutPeriodFrom"] = dtFittingFrom.SelectedDate;
                        }
                        else
                        {
                            UpdateAuditTrail("FittingOutPeriodFrom", "", Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodFrom"));
                            Item["FittingOutPeriodFrom"] = null;
                        }


                        if (!dtFittingTo.IsDateEmpty)
                        {
                            UpdateAuditTrail("FittingOutPeriodTo", dtFittingTo.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodTo"));
                            Item["FittingOutPeriodTo"] = dtFittingTo.SelectedDate;
                        }
                        else
                        {
                            UpdateAuditTrail("FittingOutPeriodTo", "", Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodTo"));
                            Item["FittingOutPeriodTo"] = null;
                        }




                        UpdateAuditTrail("FloorArea", lblSQFT.Text, Item, Item.Fields.GetFieldByInternalName("FloorArea"));
                        Item["FloorArea"] = lblSQFT.Text;

                        UpdateAuditTrail("GracePeriod", ddlGracePeriod.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("GracePeriod"));
                        Item["GracePeriod"] = ddlGracePeriod.SelectedItem.Text;




                        if (rdoHalalCertYes.Checked)
                        {
                            UpdateAuditTrail("HalalCertification", "Yes", Item, Item.Fields.GetFieldByInternalName("HalalCertification"));
                            Item["HalalCertification"] = true;
                        }
                        else
                        {
                            UpdateAuditTrail("HalalCertification", "No", Item, Item.Fields.GetFieldByInternalName("HalalCertification"));
                            Item["HalalCertification"] = false;
                        }

                        if (txtPhoneNumber.Text.Trim() != "")
                        {
                            if (rTelCheck.IsMatch(txtPhoneNumber.Text.Trim()))
                            {
                                UpdateAuditTrail("HandPhoneNumber", txtPhoneNumber.Text, Item, Item.Fields.GetFieldByInternalName("HandPhoneNumber"));
                                Item["HandPhoneNumber"] = txtPhoneNumber.Text;
                            }
                            else
                            {
                                lblErrorMsg.Text = "Hand Phone Number should contain only numbers.";
                                return;
                            }
                        }

                        // validations minimum 8 character in tel number 04th May 2017
                        if (txtPhoneNumber.Text.Trim() != "")
                        {
                            // if (rTelCheck.IsMatch(txtPhoneNumber.Text.Trim()))
                            if (txtPhoneNumber.Text.Trim().Length > 7)
                            {
                                UpdateAuditTrail("HandPhoneNumber", txtPhoneNumber.Text, Item, Item.Fields.GetFieldByInternalName("HandPhoneNumber"));
                                Item["HandPhoneNumber"] = txtPhoneNumber.Text;
                            }
                            else
                            {
                                lblErrorMsg.Text = "Hand Phone Number should contain minimum 8 numbers.";
                                return;
                            }
                        }



                        //end

                        UpdateAuditTrail("IDNumber", txtFIN.Text, Item, Item.Fields.GetFieldByInternalName("IDNumber"));
                        Item["IDNumber"] = txtFIN.Text;


                        if (txtLatePayment.Text.Trim() != "")
                        {
                            if (rAmount.IsMatch(txtLatePayment.Text.Trim()))
                            {
                                UpdateAuditTrail("LatePaymentInterestRate", txtLatePayment.Text, Item, Item.Fields.GetFieldByInternalName("LatePaymentInterestRate"));
                                Item["LatePaymentInterestRate"] = Convert.ToDouble(txtLatePayment.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Late Payment Interest Rate field should contain only numbers.";
                                return;
                            }
                        }

                        if (rdoTerm1.Checked)
                        {
                            UpdateAuditTrail("LicenseTerm", "First", Item, Item.Fields.GetFieldByInternalName("LicenseTerm"));
                            Item["LicenseTerm"] = "First";
                        }

                        if (rdoTerm2.Checked)
                        {
                            UpdateAuditTrail("LicenseTerm", "Second", Item, Item.Fields.GetFieldByInternalName("LicenseTerm"));
                            Item["LicenseTerm"] = "Second";
                        }

                        if (rdoTerm3.Checked)
                        {
                            UpdateAuditTrail("LicenseTerm", "Third", Item, Item.Fields.GetFieldByInternalName("LicenseTerm"));
                            Item["LicenseTerm"] = "Third";
                        }

                        if (txtOffNumber.Text.Trim() != "")
                        {
                            if (rTelCheck.IsMatch(txtOffNumber.Text.Trim()))
                            {
                                UpdateAuditTrail("OfficeNumber", txtOffNumber.Text.Trim(), Item, Item.Fields.GetFieldByInternalName("OfficeNumber"));
                                Item["OfficeNumber"] = txtOffNumber.Text.Trim();
                            }
                            else
                            {
                                lblErrorMsg.Text = "Office Phone Number should contain minimum 8 numbers.";
                                return;
                            }
                        }


                        // validations minimum 8 character in tel number 04th May 2017
                        if (txtOffNumber.Text.Trim() != "")
                        {
                            // if (rTelCheck.IsMatch(txtPhoneNumber.Text.Trim()))
                            if (txtOffNumber.Text.Trim().Length > 7)
                            {
                                UpdateAuditTrail("OfficeNumber", txtOffNumber.Text, Item, Item.Fields.GetFieldByInternalName("OfficeNumber"));
                                Item["OfficeNumber"] = txtOffNumber.Text;
                            }
                            else
                            {
                                lblErrorMsg.Text = "Office Phone Number should contain minimum 8 numbers.";
                                return;
                            }
                        }

                        //end validations





                        UpdateAuditTrail("PersonInCharge", txtPersonInCharge.Text, Item, Item.Fields.GetFieldByInternalName("PersonInCharge"));
                        Item["PersonInCharge"] = txtPersonInCharge.Text;


                        UpdateAuditTrail("ReasonForEarlyTermination", txtReason.Text, Item, Item.Fields.GetFieldByInternalName("ReasonForEarlyTermination"));
                        Item["ReasonForEarlyTermination"] = txtReason.Text;

                        UpdateAuditTrail("RegisteredAddress", txtRegisteredAdd.Text, Item, Item.Fields.GetFieldByInternalName("RegisteredAddress"));
                        Item["RegisteredAddress"] = txtRegisteredAdd.Text;

                        UpdateAuditTrail("Remarks", txtRemarks.Text, Item, Item.Fields.GetFieldByInternalName("Remarks"));
                        Item["Remarks"] = txtRemarks.Text;

                        string sRenewal = txtRenewalYear.Text + "-" + txtRenewalMonth.Text + "-" + txtRenewalDay.Text;
                        UpdateAuditTrail("RenewalPeriod", sRenewal, Item, Item.Fields.GetFieldByInternalName("RenewalPeriod"));
                        Item["RenewalPeriod"] = sRenewal;

                        string sRenewal2 = txtRenewalYear2.Text + "-" + txtRenewalMonth2.Text + "-" + txtRenewalDay2.Text;
                        UpdateAuditTrail("RenewalPeriod2", sRenewal, Item, Item.Fields.GetFieldByInternalName("RenewalPeriod2"));
                        Item["RenewalPeriod2"] = sRenewal2;

                        UpdateAuditTrail("RentalDueDate", ddlRentalDueDate.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("RentalDueDate"));
                        Item["RentalDueDate"] = ddlRentalDueDate.SelectedItem.Text;

                        UpdateAuditTrail("ROCUEN", txtROCNumber.Text, Item, Item.Fields.GetFieldByInternalName("ROCUEN"));
                        Item["ROCUEN"] = txtROCNumber.Text;

                        if (chkCash.Checked)
                        {
                            UpdateAuditTrail("SecurityDeposit", "Cash", Item, Item.Fields.GetFieldByInternalName("SecurityDeposit"));
                            Item["SecurityDeposit"] = "Cash";
                        }
                        if (chkBankGurantee.Checked)
                        {
                            UpdateAuditTrail("SecurityDeposit", "BG", Item, Item.Fields.GetFieldByInternalName("SecurityDeposit"));
                            Item["SecurityDeposit"] = "BG";
                        }

                        if (txtSecurityAmt.Text != "")
                        {
                            if (rAmount.IsMatch(txtSecurityAmt.Text.Trim()))
                            {
                                UpdateAuditTrail("SecurityDepositAmount", txtSecurityAmt.Text, Item, Item.Fields.GetFieldByInternalName("SecurityDepositAmount"));
                                Item["SecurityDepositAmount"] = Convert.ToDouble(txtSecurityAmt.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Security Deposit Amount field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["SecurityDepositAmount"] = "0.00";
                        }

                        if (txtServiceChgs.Text.Trim() != "")
                        {
                            if (rAmount.IsMatch(txtServiceChgs.Text.Trim()))
                            {
                                UpdateAuditTrail("ServiceCharges", txtServiceChgs.Text, Item, Item.Fields.GetFieldByInternalName("ServiceCharges"));
                                Item["ServiceCharges"] = Convert.ToDouble(txtServiceChgs.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Service & Conservancy Charges field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["ServiceCharges"] = "0.00";
                        }


                        // start 

                        // ph2 chnages on 15/04/2017	

                        if (txtSignageFees.Text.Trim() != "")
                        {
                            if (rAmount.IsMatch(txtSignageFees.Text.Trim()))
                            {
                                UpdateAuditTrail("SignageFees", txtSignageFees.Text, Item, Item.Fields.GetFieldByInternalName("SignageFees"));
                                Item["SignageFees"] = Convert.ToDouble(txtSignageFees.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Signage Fees field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["SignageFees"] = "0.00";
                        }


                        if (txtOtherFeesValue1.Text.Trim() != "")
                        {
                            if (rAmount.IsMatch(txtOtherFeesValue1.Text.Trim()))
                            {
                                UpdateAuditTrail("OtherFeesValue1", txtOtherFeesValue1.Text, Item, Item.Fields.GetFieldByInternalName("OtherFeesValue1"));
                                Item["OtherFeesValue1"] = Convert.ToDouble(txtOtherFeesValue1.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Other Fee Values 1 field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["OtherFeesValue1"] = "0.00";
                        }

                        if (txtOtherFeesValue2.Text.Trim() != "")
                        {
                            if (rAmount.IsMatch(txtOtherFeesValue2.Text.Trim()))
                            {
                                UpdateAuditTrail("OtherFeesValue2", txtOtherFeesValue2.Text, Item, Item.Fields.GetFieldByInternalName("OtherFeesValue2"));
                                Item["OtherFeesValue2"] = Convert.ToDouble(txtOtherFeesValue2.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Other Fee Values 2 field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["OtherFeesValue2"] = "0.00";
                        }


                        UpdateAuditTrail("OtherFees1", ddlOtherFees1.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("OtherFees1"));
                        Item["OtherFees1"] = ddlOtherFees1.SelectedItem.Text;

                        UpdateAuditTrail("OtherFees2", ddlOtherFees2.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("OtherFees2"));
                        Item["OtherFees2"] = ddlOtherFees2.SelectedItem.Text;

                        //end



                        if (rdoSpace1.Checked)
                        {
                            UpdateAuditTrail("SpaceClassification", "Commercial", Item, Item.Fields.GetFieldByInternalName("SpaceClassification"));
                            Item["SpaceClassification"] = "Commercial";
                        }

                        if (rdoSpace2.Checked)
                        {
                            UpdateAuditTrail("SpaceClassification", "C & CI", Item, Item.Fields.GetFieldByInternalName("SpaceClassification"));
                            Item["SpaceClassification"] = "C & CI";
                        }

                        if (rdoSpace3.Checked)
                        {
                            UpdateAuditTrail("SpaceClassification", "Utility", Item, Item.Fields.GetFieldByInternalName("SpaceClassification"));
                            Item["SpaceClassification"] = "Utility";
                        }

                        if (!dtStampDutyDate.IsDateEmpty)
                        {
                            UpdateAuditTrail("StampDutyFilingDate", dtStampDutyDate.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("StampDutyFilingDate"));
                            Item["StampDutyFilingDate"] = dtStampDutyDate.SelectedDate;
                        }
                        else
                        {
                            UpdateAuditTrail("StampDutyFilingDate", "", Item, Item.Fields.GetFieldByInternalName("StampDutyFilingDate"));
                            Item["StampDutyFilingDate"] = null;
                        }




                        if (rdoFixedUtility.Checked)
                        {
                            UpdateAuditTrail("UtilityFixedVar", "Fixed", Item, Item.Fields.GetFieldByInternalName("UtilityFixedVar"));
                            Item["UtilityFixedVar"] = "Fixed";
                        }

                        if (rdoVarUtility.Checked)
                        {
                            UpdateAuditTrail("UtilityFixedVar", "Variable", Item, Item.Fields.GetFieldByInternalName("UtilityFixedVar"));
                            Item["UtilityFixedVar"] = "Variable";
                        }

                        //ph2 

                        if (rdodirectUtility.Checked)
                        {
                            UpdateAuditTrail("UtilityFixedVar", "Direct", Item, Item.Fields.GetFieldByInternalName("UtilityFixedVar"));
                            Item["UtilityFixedVar"] = "Direct";
                        }

                        //end ph2

                        if (txtUtilitiesFees.Text != "")
                        {
                            if (rdoFixedUtility.Checked)
                            {

                                if (rAmount.IsMatch(txtUtilitiesFees.Text.Trim()))
                                {
                                    UpdateAuditTrail("UtilitiesFees", txtUtilitiesFees.Text, Item, Item.Fields.GetFieldByInternalName("UtilitiesFees"));
                                    Item["UtilitiesFees"] = Convert.ToDouble(txtUtilitiesFees.Text);
                                }
                                else
                                {
                                    lblErrorMsg.Text = "Utilities Fees field should contain only numbers.";
                                    return;
                                }
                            }
                            else
                            {
                                Item["UtilitiesFees"] = "0.00";
                            }
                        }
                        else
                        {
                            Item["UtilitiesFees"] = "0.00";
                        }



                        if (!dtSuspensionFrom.IsDateEmpty)
                        {
                            UpdateAuditTrail("SuspensionDateFrom", dtSuspensionFrom.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("SuspensionDateFrom"));
                            Item["SuspensionDateFrom"] = dtSuspensionFrom.SelectedDate;
                        }
                        else
                        {
                            UpdateAuditTrail("SuspensionDateFrom", "", Item, Item.Fields.GetFieldByInternalName("SuspensionDateFrom"));
                            Item["SuspensionDateFrom"] = null;
                        }


                        if (!dtSuspensionTo.IsDateEmpty)
                        {
                            UpdateAuditTrail("SuspensionDateTo", dtSuspensionTo.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("SuspensionDateTo"));
                            Item["SuspensionDateTo"] = dtSuspensionTo.SelectedDate;
                        }
                        else
                        {
                            UpdateAuditTrail("SuspensionDateTo", "", Item, Item.Fields.GetFieldByInternalName("SuspensionDateTo"));
                            Item["SuspensionDateTo"] = null;

                        }



                        //end


                        //if New Agreement, then update last record sequence...(disabled ph2)

                        /*
                        if (!bEdit)
                        {
                            SPList appSettings = web.Lists["ApplicationSettings"];
                            SPQuery querySet = new SPQuery();

                            //ph2
                            if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2
                            {
                                querySet.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "LastAgreementNumber");
                            }
                            else
                            {
                                querySet.Query = string.Format("<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>{0}</Value></Eq></Where>", "LastAgreementNumberDraft");
                            }

                            //ph2 end

                            SPListItemCollection aCol = appSettings.GetItems(querySet);

                            if (aCol.Count > 0)
                            {
                                SPListItem oItem = aCol[0];

                                string[] sRecordCount = lblRecordNumber.Text.Split(new string[] { "-" }, StringSplitOptions.None);
                                if (sRecordCount.Length > 0)
                                {
                                    oItem["Value"] = sRecordCount[2];
                                }
                                else
                                {
                                    oItem["Value"] = "9999";
                                }

                                oItem.Update();
                            }
                        }

                        */

                        //ph2 changes disabled

                        UpdateAuditTrail("TenantName", ddlTenantName.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("TenantName"));
                        Item["TenantName"] = ddlTenantName.SelectedItem.Text;

                        // end SK

                        UpdateAuditTrail("TenantTradingName", txtTradingName.Text, Item, Item.Fields.GetFieldByInternalName("TenantTradingName"));
                        Item["TenantTradingName"] = txtTradingName.Text.ToUpper();

                        string sTenure = txtTenureYear.Text + "-" + txtTenureMonth.Text + "-" + txtTenureDay.Text;
                        UpdateAuditTrail("Tenure", sTenure, Item, Item.Fields.GetFieldByInternalName("Tenure"));
                        Item["Tenure"] = sTenure;


                        UpdateAuditTrail("TradeCategory", ddlTradeCat.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("TradeCategory"));
                        Item["TradeCategory"] = ddlTradeCat.SelectedItem.Text;

                        if (rdoTypeOption1.Checked)
                        {
                            UpdateAuditTrail("TenancyRecordType", "New", Item, Item.Fields.GetFieldByInternalName("TenancyRecordType"));
                            Item["TenancyRecordType"] = "New";
                        }
                        if (rdoTypeOption2.Checked)
                        {
                            UpdateAuditTrail("TenancyRecordType", "Renewal", Item, Item.Fields.GetFieldByInternalName("TenancyRecordType"));
                            Item["TenancyRecordType"] = "Renewal";
                        }
                        if (rdoTypeOption3.Checked)
                        {
                            UpdateAuditTrail("TenancyRecordType", "Extension", Item, Item.Fields.GetFieldByInternalName("TenancyRecordType"));
                            Item["TenancyRecordType"] = "Extension";
                        }


                        //added by SK for new text field type from ddl to text
                        UpdateAuditTrail("TypeOfCompany", txtCompanyType.Text, Item, Item.Fields.GetFieldByInternalName("TypeOfCompany"));
                        Item["TypeOfCompany"] = txtCompanyType.Text;
                        //end

                        UpdateAuditTrail("TypeOfTrade", ddlTradeType.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("TypeOfTrade"));
                        Item["TypeOfTrade"] = ddlTradeType.SelectedItem.Text;

                        if (rdoUnitOption1.Checked)
                        {
                            UpdateAuditTrail("UnitType", "Single", Item, Item.Fields.GetFieldByInternalName("UnitType"));
                            Item["UnitType"] = "Single";
                        }

                        if (rdoUnitOption2.Checked)
                        {
                            UpdateAuditTrail("UnitType", "Multiple Units", Item, Item.Fields.GetFieldByInternalName("UnitType"));
                            Item["UnitType"] = "Multiple Units";
                        }

                        //ph2 changes

                        if (rdopaymentoption1.Checked)
                        {
                            UpdateAuditTrail("PaymentOption", "Monthly", Item, Item.Fields.GetFieldByInternalName("PaymentOption"));
                            Item["PaymentOption"] = "Monthly";
                        }

                        if (rdopaymentoption2.Checked)
                        {
                            UpdateAuditTrail("PaymentOption", "LumpSum", Item, Item.Fields.GetFieldByInternalName("PaymentOption"));
                            Item["PaymentOption"] = "LumpSum";
                        }


                        if (rdofixedlatepayment.Checked)
                        {

                            UpdateAuditTrail("LatePaymentInterestRateOption", "Fixed", Item, Item.Fields.GetFieldByInternalName("LatePaymentInterestRateOption"));
                            Item["LatePaymentInterestRateOption"] = "Fixed";


                        }

                        if (rdovariablelatepayment.Checked)
                        {
                            UpdateAuditTrail("LatePaymentInterestRateOption", "Prevaling", Item, Item.Fields.GetFieldByInternalName("LatePaymentInterestRateOption"));

                            Item["LatePaymentInterestRateOption"] = "Prevaling";

                        }

                        //end ph2 changes

                        if (rdoAgreementOption1.Checked)
                        {
                            UpdateAuditTrail("TypeOfAgreement", "Tenancy", Item, Item.Fields.GetFieldByInternalName("TypeOfAgreement"));
                            Item["TypeOfAgreement"] = "Tenancy";
                        }

                        if (rdoAgreementOption2.Checked)
                        {
                            UpdateAuditTrail("TypeOfAgreement", "Licence", Item, Item.Fields.GetFieldByInternalName("TypeOfAgreement"));
                            Item["TypeOfAgreement"] = "Licence";
                        }

                        if (txtUtilitiesDeposit.Text != "")
                        {
                            if (rAmount.IsMatch(txtUtilitiesDeposit.Text.Trim()))
                            {
                                UpdateAuditTrail("UtilitiesDepositAmount", txtUtilitiesDeposit.Text, Item, Item.Fields.GetFieldByInternalName("UtilitiesDepositAmount"));
                                Item["UtilitiesDepositAmount"] = Convert.ToDouble(txtUtilitiesDeposit.Text);
                            }
                            else
                            {
                                lblErrorMsg.Text = "Utilities Deposit Amount field should contain only numbers.";
                                return;
                            }
                        }
                        else
                        {
                            Item["UtilitiesDepositAmount"] = "0.00";
                        }

                        if (txtRemarks.Text != "")
                        {
                            UpdateAuditTrail("Remarks", txtRemarks.Text, Item, Item.Fields.GetFieldByInternalName("Remarks"));
                            Item["Remarks"] = txtRemarks.Text;
                        }
                        //Item["AgreementTypeInt"] = FormTpe;

                        Item["AgreementTypeInt"] = "Tenancy Agreement";
                        Item["FormName"] = FormType;
                        Item["EditUrl"] = EditUrl;
                        Item["ViewUrl"] = ViewUrl;

                        // if ((drpAgreementStatus.SelectedItem.Text == "Pending for Approval") && (mRecord == "Draft") && (dflag == "Yes"))
                        if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft") && (dflag == "Yes"))
                        {
                            string mode = "TMS";
                            genTenancyRecordNumber(mode);
                            updateTenancyRecordNumber(mode);
                            Item["AgreementStatus"] = "Pending for Approval";
                        }

                        UpdateAuditTrail("TenancyRecordNumber", lblRecordNumber.Text, Item, Item.Fields.GetFieldByInternalName("TenancyRecordNumber"));
                        Item["TenancyRecordNumber"] = lblRecordNumber.Text;

                        //ph2 update previous tenenacy record - Renewal and Novation

                        UpdateAuditTrail("TenancyRecordNumberOld", lblPrevRecordNumber.Text, Item, Item.Fields.GetFieldByInternalName("TenancyRecordNumberOld"));
                        Item["TenancyRecordNumberOld"] = lblPrevRecordNumber.Text;

                        Item["AgreementTypeInt"] = FormType;
                        Item["EditUrl"] = EditUrl;
                        Item["ViewUrl"] = ViewUrl;



                        Item.Update();
                        iRecord = Item.ID;
                        iProcess = 1;
                        //AddToLogFile("BtnSave == TenancyAgreementID == " + iRecord.ToString(), web.CurrentUser.LoginName);

                        DateTime dtLEndDate = DateTime.Today;
                        DeleteLeaseAgreementLicenseSave(iRecord.ToString());
                        AddLeaseAgreementLicenseSave(iRecord.ToString(), ref dtLEndDate);


                        #region Update Unit Info List

                        if (iProcess == 1)
                        {

                            //Update Unit Info List...
                            SPList UnitInfoList = web.Lists[strUnitInformationList];
                            foreach (int i in lbxUnitNumber.GetSelectedIndices())
                            {
                                int iSelectedID = Convert.ToInt16(lbxUnitNumber.Items[i].Value);
                                SPListItem UnitItem = UnitInfoList.GetItemById(iSelectedID);

                                switch (drpAgreementStatus.SelectedItem.Text)
                                {
                                    case "Approved":
                                        UnitItem["Status"] = "Tenanted";
                                        UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                        break;

                                    case "Pending for Approval":
                                        UnitItem["Status"] = "Committed";
                                        UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                        break;
                                    case "Submit for Approval":
                                        UnitItem["Status"] = "Committed";
                                        UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                        break;
                                    case "ReSubmission":
                                        UnitItem["Status"] = "Committed";
                                        UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                        break;
                                    case "Draft":
                                        UnitItem["Status"] = "Committed";
                                        UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                        break;

                                    case "Rejected":
                                        UnitItem["Status"] = "Available";
                                        break;
                                    case "Cancelled":
                                        UnitItem["Status"] = "Available";
                                        break;
                                    case "Deleted":
                                        UnitItem["Status"] = "Available";
                                        break;

                                    default:
                                        UnitItem["Status"] = "Available";
                                        break;
                                }
                                UnitItem.Update();
                            }
                            //UnitInfoList.Update();
                        }
                        #endregion




                        //	if ((drpAgreementStatus.SelectedItem.Text == "Pending for Approval") && (mRecord == "Draft"))
                        if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft") && (dflag == "Yes"))
                        {
                            deletedraft(); //ph2 to delete draft
                        }

                        //    if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft") && (dflag == "Yes"))


                        //#region Update License Details

                        //if (iProcess == 1)
                        //{

                        //    //Save License details....
                        //    SetRowData();
                        //    DataTable table = ViewState["CurrentTable"] as DataTable;



                        //    //ph2 

                        //    SPList LicenseDetailList;

                        //    //	if ((drpAgreementStatus.SelectedItem.Text != "Draft") && (mRecord == "Draft")) //ph2

                        //    //	if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2

                        //    if (mRecord == "Draft")
                        //    {
                        //        LicenseDetailList = web.Lists[strTestTenantListDraft];

                        //    }
                        //    else
                        //    {
                        //        LicenseDetailList = web.Lists[strTestTenantList];
                        //    }


                        //    //end ph2


                        //    SPListItem LicenseItem = null;
                        //    double contractvalue = 0;

                        //    if (table.Rows.Count > 0)
                        //    {
                        //        foreach (DataRow row in table.Rows)
                        //        {
                        //            string ComplianceTitle1 = row.ItemArray[0].ToString();
                        //            string ComplianceTitle2 = row.ItemArray[1].ToString();
                        //            string ComplianceTitle3 = row.ItemArray[2].ToString();
                        //            string ComplianceTitle4 = row.ItemArray[3].ToString();
                        //            string ComplianceTitle5 = row.ItemArray[4].ToString();
                        //            string ComplianceTitle6 = row.ItemArray[5].ToString();
                        //            string ComplianceTitle7 = row.ItemArray[6].ToString();

                        //            //AddToLogFile("BtnSave == ComplianceTitle 5 == " + ComplianceTitle5, web.CurrentUser.LoginName);

                        //            if (ComplianceTitle1 != null || ComplianceTitle2 != null || ComplianceTitle3 != null || ComplianceTitle4 != null || ComplianceTitle5 != null)
                        //            {
                        //                //AddToLogFile("BtnSave == ComplianceTitle 1 == " + ComplianceTitle1, web.CurrentUser.LoginName);

                        //                if ((ComplianceTitle5.Trim() == "0") || (!bEdit))
                        //                {
                        //                    //new code ph2  switching draft to pending for approval adding new rows
                        //                    if (drpAgreementStatus.SelectedItem.Text == "Draft")
                        //                    {
                        //                        LicenseDetailList = web.Lists[strTestTenantListDraft];
                        //                         LicenseItem = LicenseDetailList.Items.Add();
                        //                    } else 

                        //                    {
                        //                        LicenseDetailList = web.Lists[strTestTenantList];
                        //                        LicenseItem = LicenseDetailList.Items.Add();
                        //                    }


                        //                //	LicenseDetailList = web.Lists[strTestTenantListDraft];
                        //                //	LicenseItem = LicenseDetailList.Items.Add();
                        //                }
                        //                else if ((bEdit) && ComplianceTitle5.Trim() != "0")
                        //                {

                        //                    // disable ph2 	LicenseItem = LicenseDetailList.GetItemById(Convert.ToInt32(ComplianceTitle5));

                        //                    //new code ph2  switching draft to pending for approval

                        //                    if ((drpAgreementStatus.SelectedItem.Text == "Pending for Approval") && (mRecord == "Draft"))
                        //                    {
                        //                        LicenseDetailList = web.Lists[strTestTenantList];
                        //                        LicenseItem = LicenseDetailList.Items.Add();
                        //                    }
                        //                    else
                        //                    {
                        //                        LicenseItem = LicenseDetailList.GetItemById(Convert.ToInt32(ComplianceTitle5));
                        //                    }

                        //                    //end ph2 

                        //                }
                        //                else
                        //                {
                        //                    lblErrorMsg.Text = "There is some issue in the License Details. Please contact System Administrator.";
                        //                    AddToLogFile("BtnSave == License Item == " + ComplianceTitle5.ToString(), web.CurrentUser.LoginName);
                        //                    return;
                        //                }
                        //                if (LicenseItem != null)
                        //                {
                        //                    LicenseItem["TenancyAgreementID"] = iRecord.ToString();

                        //                    //AddToLogFile("BtnSave == ComplianceTitle 2 == " + ComplianceTitle2, web.CurrentUser.LoginName);

                        //                    ComplianceTitle1 = ComplianceTitle1.Replace(" 12:00:00 AM", "");
                        //                    ComplianceTitle2 = ComplianceTitle2.Replace(" 12:00:00 AM", "");
                        //                    ComplianceTitle1 = ComplianceTitle1.Replace(" 00:00:00", "");
                        //                    ComplianceTitle2 = ComplianceTitle2.Replace(" 00:00:00", "");

                        //                    LicenseItem["LicenseStartDate"] = ComplianceTitle1;

                        //                    LicenseItem["LicenseEndDate"] = ComplianceTitle2;



                        //                    if (ComplianceTitle3.Trim() != "")
                        //                    {
                        //                        if (rAmount.IsMatch(ComplianceTitle3.Trim()))
                        //                        {
                        //                            UpdateAuditTrail("MonthlyRent", ComplianceTitle3, LicenseItem, LicenseItem.Fields.GetFieldByInternalName("MonthlyRent"));
                        //                            LicenseItem["MonthlyRent"] = ComplianceTitle3;


                        //                        }
                        //                        else
                        //                        {
                        //                            lblErrorMsg.Text = "Monthly Rent field should contain only numbers.";
                        //                            return;
                        //                        }
                        //                    }
                        //                    else
                        //                    {
                        //                        LicenseItem["MonthlyRent"] = "0.00";
                        //                    }


                        //                    //end ph2 claculate


                        //                    if (ComplianceTitle4.Trim() != "")
                        //                    {
                        //                        if (rAmount.IsMatch(ComplianceTitle4.Trim()))
                        //                        {
                        //                            UpdateAuditTrail("RentPSF", ComplianceTitle4, LicenseItem, LicenseItem.Fields.GetFieldByInternalName("RentPSF"));
                        //                            LicenseItem["RentPSF"] = ComplianceTitle4;
                        //                        }
                        //                        else
                        //                        {
                        //                            lblErrorMsg.Text = "Monthly Rent field should contain only numbers.";
                        //                            return;
                        //                        }
                        //                    }
                        //                    else
                        //                    {
                        //                        LicenseItem["RentPSF"] = "0.00";
                        //                    }

                        //                    if (ComplianceTitle6.Trim() != "")
                        //                    {
                        //                        LicenseItem["NetFirstRent"] = ComplianceTitle6;

                        //                    }

                        //                    if (ComplianceTitle7.Trim() != "")
                        //                    {
                        //                        LicenseItem["NetLastRent"] = ComplianceTitle7;
                        //                    }

                        //                    LicenseItem["AgreementSQFT"] = lblSQFT.Text;

                        //                    LicenseItem["CCName"] = iCCID.ToString();

                        //                    LicenseItem.Update();
                        //                }
                        //            }
                        //        }
                        //        //LicenseDetailList.Update();
                        //        Page.ClientScript.RegisterStartupScript(this.GetType(), "Message", "<script type='text/javascript'>alert('Submitted to Business Development Division for clearance');</script>");

                        //    }
                        //    else
                        //    {
                        //        AddToLogFile("btnSave_Click", "No License Details found");
                        //        //no code...
                        //    }

                        //    iProcess = 0;

                        //}
                        //#endregion


                        Response.Redirect("..\\default.aspx");
                    }
                }


            }
            catch (Exception ex)
            {
                AddToLogFile("Button Save In Tenancy Agreement Form:", "Error = " + ex.Message);
            }
        }



        //ph2 delete liceses

        // ph2 delete draft 

        public void deleteAllLicenses()
        {

            //ph2 draft delete start

            SPList TADList;
            SPListItem ditem;
            SPList TADLList;


            SPWeb web = site.OpenWeb();
            piRecord = Convert.ToInt32(Request.QueryString["drID"]);
            TADList = web.Lists[strAgreementListNameDraft];
            TADLList = web.Lists[strTestTenantListDraft]; // LICENSE DETAILS

            SPQuery oLicQueryDraftTA = new SPQuery();
            oLicQueryDraftTA.Query = "<Where><Eq><FieldRef Name='ID' /><Value Type='Text'>" + piRecord.ToString() + "</Value></Eq></Where>";
            SPListItemCollection LicenseListCollectionDraftTA = TADList.GetItems(oLicQueryDraftTA);
            int countItemTA = LicenseListCollectionDraftTA.Count;
            for (int i = 0; i < countItemTA; i++)
            {
                LicenseListCollectionDraftTA.Delete(0);
            }

            // END

            // DELETE LICENSE LIST
            SPQuery oLicQueryDraft = new SPQuery();
            oLicQueryDraft.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID' /><Value Type='Text'>" + piRecord.ToString() + "</Value></Eq></Where>";
            SPListItemCollection LicenseListCollectionDraft = TADLList.GetItems(oLicQueryDraft);
            int countItem = LicenseListCollectionDraft.Count;
            for (int i = 0; i < countItem; i++)
            {
                LicenseListCollectionDraft.Delete(0);
            }

        }

        //end ph2 draft delete



        // ph2 delete draft 

        public void deletedraft()
        {

            //ph2 draft delete start

            SPList TADList;
            SPListItem ditem;
            SPList TADLList;

            if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft"))

            // if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft") && (dflag == "Yes"))


            {
                SPWeb web = site.OpenWeb();
                piRecord = Convert.ToInt32(Request.QueryString["drID"]);
                TADList = web.Lists[strAgreementListNameDraft];
                TADLList = web.Lists[strTestTenantListDraft]; // LICENSE DETAILS

                SPQuery oLicQueryDraftTA = new SPQuery();
                oLicQueryDraftTA.Query = "<Where><Eq><FieldRef Name='ID' /><Value Type='Text'>" + piRecord.ToString() + "</Value></Eq></Where>";
                SPListItemCollection LicenseListCollectionDraftTA = TADList.GetItems(oLicQueryDraftTA);
                int countItemTA = LicenseListCollectionDraftTA.Count;
                for (int i = 0; i < countItemTA; i++)
                {
                    LicenseListCollectionDraftTA.Delete(0);
                }

                // END

                // DELETE LICENSE LIST
                SPQuery oLicQueryDraft = new SPQuery();
                oLicQueryDraft.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID' /><Value Type='Text'>" + piRecord.ToString() + "</Value></Eq></Where>";
                SPListItemCollection LicenseListCollectionDraft = TADLList.GetItems(oLicQueryDraft);
                int countItem = LicenseListCollectionDraft.Count;
                for (int i = 0; i < countItem; i++)
                {
                    LicenseListCollectionDraft.Delete(0);
                }

            }

            //end ph2 draft delete

        }


        //end ph2 delete draft

        /// <summary>
        /// Creates the new row When User Clicks on AddButton
        /// </summary>
        private void AddNewRow()
        {
            int rowIndex = 0;

            if (ViewState["CurrentTable"] != null)
            {
                DataTable dtCurrentTable = (DataTable)ViewState["CurrentTable"];
                DataRow drCurrentRow = null;
                if (dtCurrentTable.Rows.Count > 0)
                {
                    for (int i = 1; i <= dtCurrentTable.Rows.Count; i++)
                    {
                        DateTimeControl txtCompliance1 = (DateTimeControl)grvTenantDetails.Rows[rowIndex].Cells[1].FindControl("TenancyStartDate");
                        DateTimeControl txtCompliance2 = (DateTimeControl)grvTenantDetails.Rows[rowIndex].Cells[2].FindControl("TenancyEndDate");
                        TextBox txtCompliance3 = (TextBox)grvTenantDetails.Rows[rowIndex].Cells[3].FindControl("txtCompliance3");
                        TextBox txtCompliance4 = (TextBox)grvTenantDetails.Rows[rowIndex].Cells[4].FindControl("txtCompliance4");

                        // FIXING PH2 
                        Label lblCompliance5 = (Label)grvTenantDetails.Rows[rowIndex].Cells[5].FindControl("lblLicenseDetailID");
                        Label lblCompliance6 = (Label)grvTenantDetails.Rows[rowIndex].Cells[6].FindControl("lblFirstRent");
                        Label lblCompliance7 = (Label)grvTenantDetails.Rows[rowIndex].Cells[7].FindControl("lblLastRent");

                        //END FIXING

                        drCurrentRow = dtCurrentTable.NewRow();
                        dtCurrentTable.Rows[i - 1]["Col1"] = txtCompliance1.SelectedDate.Date;
                        dtCurrentTable.Rows[i - 1]["Col2"] = txtCompliance2.SelectedDate.Date;
                        dtCurrentTable.Rows[i - 1]["Col3"] = txtCompliance3.Text;
                        dtCurrentTable.Rows[i - 1]["Col4"] = txtCompliance4.Text;

                        //FIX PH2 
                        if (lblCompliance5 != null)
                        {
                            dtCurrentTable.Rows[i - 1]["Col5"] = lblCompliance5.Text;
                        }
                        dtCurrentTable.Rows[i - 1]["Col6"] = lblCompliance6.Text;
                        dtCurrentTable.Rows[i - 1]["Col7"] = lblCompliance7.Text;

                        //END FIX

                        rowIndex++;
                    }
                    if (dtCurrentTable.Rows.Count < 10)
                    {
                        dtCurrentTable.Rows.Add(drCurrentRow);
                    }
                    ViewState["CurrentTable"] = dtCurrentTable;

                    grvTenantDetails.DataSource = dtCurrentTable;
                    grvTenantDetails.DataBind();
                }
            }
            else
            {
                Response.Write("ViewState is null");
            }
            SetPreviousData();
        }

        // PH2 

        public void unitadd(int unitid)
        {
            using (SPWeb web = site.OpenWeb())
            {
                string preservevalue = "";
                SPList UnitInfoList = web.Lists[strUnitInformationList];
                SPListItem unitno = UnitInfoList.GetItemById(unitid);


                if (unitno["Floor"] != null)
                {
                    string previuosvalue = lblselectedunitno.Text;
                    lblselectedunitno.Text = unitno["Floor"].ToString();
                    if (previuosvalue != "")
                    {
                        lblselectedunitno.Text = previuosvalue + unitno["Floor"].ToString();

                    }
                    else
                    {

                        lblselectedunitno.Text = unitno["Floor"].ToString();
                    }

                    preservevalue += lblselectedunitno.Text;
                    lblselectedunitno.Text = preservevalue;
                }

            }


        }

        //PH2


        /// <summary>
        /// This method shows the previous data in the row 
        /// </summary>
        private void SetPreviousData()
        {
            int rowIndex = 0;
            if (ViewState["CurrentTable"] != null)
            {
                DataTable dt = (DataTable)ViewState["CurrentTable"];
                if (dt.Rows.Count > 0)
                {
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        DateTimeControl txtCompliance1 = (DateTimeControl)grvTenantDetails.Rows[rowIndex].Cells[1].FindControl("TenancyStartDate");
                        DateTimeControl txtCompliance2 = (DateTimeControl)grvTenantDetails.Rows[rowIndex].Cells[2].FindControl("TenancyEndDate");
                        TextBox txtCompliance3 = (TextBox)grvTenantDetails.Rows[rowIndex].Cells[3].FindControl("txtCompliance3");
                        TextBox txtCompliance4 = (TextBox)grvTenantDetails.Rows[rowIndex].Cells[4].FindControl("txtCompliance4");

                        // PH2 FIX EDITING DRAFT
                        Label lblCompliance5 = (Label)grvTenantDetails.Rows[rowIndex].Cells[5].FindControl("lblLicenseDetailID");
                        Label lblCompliance6 = (Label)grvTenantDetails.Rows[rowIndex].Cells[6].FindControl("lblFirstRent");
                        Label lblCompliance7 = (Label)grvTenantDetails.Rows[rowIndex].Cells[7].FindControl("lblLastRent");


                        //PH2 END FIXING


                        txtCompliance1.SelectedDate = Convert.ToDateTime(dt.Rows[i]["Col1"].ToString());
                        txtCompliance2.SelectedDate = Convert.ToDateTime(dt.Rows[i]["Col2"].ToString());
                        txtCompliance3.Text = dt.Rows[i]["Col3"].ToString();
                        txtCompliance4.Text = dt.Rows[i]["Col4"].ToString();

                        //PH2 FIX 

                        lblCompliance5.Text = dt.Rows[i]["Col5"].ToString();
                        lblCompliance6.Text = dt.Rows[i]["Col6"].ToString();
                        lblCompliance7.Text = dt.Rows[i]["Col7"].ToString();



                        // END PH2


                        rowIndex++;
                    }
                }
            }
        }

        protected void ButtonAdd_Click(object sender, EventArgs e)
        {
            try
            {
                AddNewRow();
            }
            catch (Exception ex)
            { AddToLogFile("ButtonAdd in TenancyDetails", ex.Message); }
        }

        protected void grvTenantDetails_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            SetRowData();
            if (ViewState["CurrentTable"] != null)
            {

                DataTable dt = (DataTable)ViewState["CurrentTable"];
                DataRow drCurrentRow = null;
                int rowIndex = Convert.ToInt32(e.RowIndex);
                if (dt.Rows.Count > 1)
                {

                    //PH2 DELETE ROWS BACKEND
                    string deleterowid = dt.Rows[rowIndex]["Col5"].ToString();
                    // int deleterowID = Convert.ToInt32(deleterowID);

                    int ideleterowID = Convert.ToInt32(deleterowid);

                    if (ideleterowID > 0)
                    {

                        SPWeb web = site.OpenWeb();
                        SPList LicenseDetailList;

                        if (mRecord == "Draft")
                        {
                            LicenseDetailList = web.Lists[strTestTenantListDraft];

                        }
                        else
                        {
                            LicenseDetailList = web.Lists[strTestTenantList];
                        }

                        SPListItem DeleteItem = LicenseDetailList.GetItemById(Convert.ToInt32(deleterowid));

                        DeleteItem.Delete();

                    }









                    // END PH2


                    //	string deleterowid1 = dt.Rows[rowIndex-1]["Col4"].ToString();


                    dt.Rows.Remove(dt.Rows[rowIndex]);



                    //lblCompliance5.Text = dt.Rows[i]["Col5"].ToString();

                    //txtCompliance3.Text = dt.Rows[i]["Col3"].ToString();

                    drCurrentRow = dt.NewRow();
                    ViewState["CurrentTable"] = dt;
                    grvTenantDetails.DataSource = dt;
                    grvTenantDetails.DataBind();
                    SetPreviousData();
                }
            }
        }

        private void SetRowData()
        {
            try
            {
                int rowIndex = 0;

                if (ViewState["CurrentTable"] != null)
                {
                    DataTable dtCurrentTable = (DataTable)ViewState["CurrentTable"];
                    DataRow drCurrentRow = null;
                    if (dtCurrentTable.Rows.Count > 0)
                    {
                        for (int i = 1; i <= dtCurrentTable.Rows.Count; i++)
                        {
                            DateTimeControl txtCompliance1 = (DateTimeControl)grvTenantDetails.Rows[rowIndex].Cells[1].FindControl("TenancyStartDate");
                            DateTimeControl txtCompliance2 = (DateTimeControl)grvTenantDetails.Rows[rowIndex].Cells[2].FindControl("TenancyEndDate");
                            TextBox txtCompliance3 = (TextBox)grvTenantDetails.Rows[rowIndex].Cells[3].FindControl("txtCompliance3");
                            TextBox txtCompliance4 = (TextBox)grvTenantDetails.Rows[rowIndex].Cells[4].FindControl("txtCompliance4");
                            Label lblCompliance5 = (Label)grvTenantDetails.Rows[rowIndex].Cells[5].FindControl("lblLicenseDetailID");
                            Label lblCompliance6 = (Label)grvTenantDetails.Rows[rowIndex].Cells[6].FindControl("lblFirstRent");
                            Label lblCompliance7 = (Label)grvTenantDetails.Rows[rowIndex].Cells[7].FindControl("lblLastRent");

                            drCurrentRow = dtCurrentTable.NewRow();
                            dtCurrentTable.Rows[i - 1]["Col1"] = txtCompliance1.SelectedDate.Date;
                            dtCurrentTable.Rows[i - 1]["Col2"] = txtCompliance2.SelectedDate.Date;
                            dtCurrentTable.Rows[i - 1]["Col3"] = txtCompliance3.Text;
                            dtCurrentTable.Rows[i - 1]["Col4"] = txtCompliance4.Text;
                            if (lblCompliance5 != null)
                            {
                                dtCurrentTable.Rows[i - 1]["Col5"] = lblCompliance5.Text;
                            }
                            dtCurrentTable.Rows[i - 1]["Col6"] = lblCompliance6.Text;
                            dtCurrentTable.Rows[i - 1]["Col7"] = lblCompliance7.Text;
                            rowIndex++;
                        }
                        ViewState["CurrentTable"] = dtCurrentTable;
                    }
                }
                else
                {
                    Response.Write("ViewState is null");
                }
                //SetPreviousData();
            }
            catch (Exception ex)
            {
                AddToLogFile("in SetRowData method", ex.Message);
            }
        }


        protected void UpdateAuditTrail(string sFieldName, string sNewValue, SPListItem oRecordItem, SPField oRecordField)
        {
            string strAuditTrailList = "TMSAuditTrail";
            string sOldValue = "";

            try
            {
                SPSecurity.RunWithElevatedPrivileges(delegate ()
                {
                    using (SPWeb web = site.OpenWeb())
                    {
                        SPList ATList = web.Lists[strAuditTrailList];
                        SPListItem ATItem = ATList.Items.Add();
                        if (oRecordItem[sFieldName] != null)
                        {
                            sOldValue = oRecordItem[sFieldName].ToString().Trim();
                        }

                        //add in audit trail is the value is different...
                        if (sOldValue != sNewValue)
                        {
                            ATItem["OldValue"] = sOldValue;
                            ATItem["NewValue"] = sNewValue;
                            ATItem["ListName"] = oRecordItem.ParentList.Title;
                            if (oRecordItem["ID"] != null)
                            {
                                ATItem["RecordID"] = oRecordItem.ID.ToString();
                            }
                            else
                            {
                                ATItem["RecordID"] = "0";
                            }
                            ATItem["RecordModifiedOn"] = DateTime.Today;
                            if (oRecordItem["Created"] != null)
                            {
                                ATItem["RecordCreatedOn"] = oRecordItem["Created"];
                            }
                            else
                            {
                                ATItem["RecordCreatedOn"] = DateTime.Today;
                            }
                            if (oRecordItem["Author"] != null)
                            {
                                ATItem["RecordCreatedBy"] = oRecordItem["Author"];
                            }
                            else
                            {
                                ATItem["RecordCreatedBy"] = web.CurrentUser;
                            }
                            ATItem["RecordModifiedBy"] = web.CurrentUser;
                            ATItem["FieldChanged"] = oRecordField.Title;
                            ATItem["FieldType"] = oRecordField.TypeDisplayName;
                            AddToLogFile("Update Audit Trail == " + oRecordField.Title, web.CurrentUser.LoginName);

                            ATItem.Update();
                        }
                        else
                        {
                            //do nothing..
                        }

                    }
                });
            }
            catch (Exception ex)
            {
                AddToLogFile("UpdateAuditTrail => ", ex.Message);
            }


        }


        public bool IsValidEmail(string emailaddress)
        {
            try
            {
                System.Net.Mail.MailAddress m = new System.Net.Mail.MailAddress(emailaddress);

                return true;
            }
            catch (FormatException)
            {
                return false;
            }
        }

        protected void ddlTradeCat_SelectedIndexChanged(object sender, EventArgs e)
        {
            rdoHalalCertNo.Enabled = true;
            rdoHalalCertYes.Enabled = true;

            if (ddlTradeCat.SelectedItem.Text != "Food and Beverage")
            {
                rdoHalalCertNo.Enabled = false;
                rdoHalalCertYes.Enabled = false;
            }

            ddlTradeType.Items.Clear();

            using (SPWeb web = site.OpenWeb())
            {
                SPList TTList = web.Lists[strTradeCategoryList];
                SPQuery oTTquery = new SPQuery();
                oTTquery.Query = "<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>" + ddlTradeCat.SelectedItem.Text + "</Value></Eq></Where>";
                SPListItemCollection TTCol = TTList.GetItems(oTTquery);

                if (TTCol.Count > 0)
                {
                    string sTradeType = TTCol[0]["TradeType"].ToString();
                    string[] sTradeTypeArr = sTradeType.Split(',');

                    foreach (string sTradeTypeOption in sTradeTypeArr)
                    {
                        ddlTradeType.Items.Add(sTradeTypeOption);
                    }
                }
                //ph2 for draft
                else if ((TTCol.Count == 0) && (mRecord == "Draft"))
                {
                    ddlTradeType.Items.Add(new ListItem("Select Trade Type"));
                }

                // end ph2 draft

                else
                {
                    this.Page.RegisterStartupScript("AlertMsg", "<script type='text/javascript'>alert('The selected Trade Category does not have any Trade Type.');</script>");
                }
            }
        }


        public bool GetGroups(string groupName)
        {
            SPUser user = SPContext.Current.Web.CurrentUser;
            SPWeb site = SPContext.Current.Web;
            SPGroup managerGroup = site.Groups[groupName];
            return site.IsCurrentUserMemberOfGroup(managerGroup.ID);
        }

        protected void txtCompliance3_TextChanged(object sender, EventArgs e)
        {
            TextBox oMonthlyRent = (TextBox)sender;
            GridViewRow currentRow = (GridViewRow)oMonthlyRent.Parent.Parent;
            double dMonthlyRent = Convert.ToDouble(oMonthlyRent.Text);
            int rowindex = 0;
            rowindex = currentRow.RowIndex;

            //PH2 fix kick put page
            rowindex = currentRow.RowIndex;

            double dRent;

            if (lblSQFT.Text == "")
            {
                dRent = 0;
            }

            else
            {

                dRent = Math.Round(Convert.ToDouble(oMonthlyRent.Text) / Convert.ToDouble(lblSQFT.Text), 2);
            }

            // END PH2 CHANGES

            //auto calculate contract value and approving authority

            // calculateTotalLease(dMonthlyRent);

            //end 

            TextBox oText2 = (TextBox)currentRow.Cells[3].FindControl("txtCompliance4");
            oText2.Text = dRent.ToString();

            lbltempbalancedaysFirst.Text = "0.00";  // ph2

            lbltempbalancedaysLast.Text = "0.00";   //ph2

            lbltotaltenuremonths.Text = ""; // ph2

            //ph2 

            // ph2 
            double dMonthlyRentLbl1 = 0.00;
            double dMonthlyRentLbl2 = 0.00;
            double dMonthlyRentLbl3 = 0.00;
            double dMonthlyRentLbl4 = 0.00;
            double dMonthlyRentLbl5 = 0.00;
            double dMonthlyRentLbl6 = 0.00;
            double dMonthlyRentLbl7 = 0.00;

            //end ph2


            //ph2 


            if (txtSecurityAmt.Text.Trim() != "")
            {
                dMonthlyRentLbl1 = Convert.ToDouble(txtSecurityAmt.Text);
            }

            if (txtUtilitiesDeposit.Text.Trim() != "")
            {
                dMonthlyRentLbl2 = Convert.ToDouble(txtUtilitiesDeposit.Text);
            }

            if (txtFittingDeposit.Text.Trim() != "")
            {
                dMonthlyRentLbl3 = Convert.ToDouble(txtFittingDeposit.Text);
            }

            if (txtServiceChgs.Text.Trim() != "")
            {
                dMonthlyRentLbl4 = Convert.ToDouble(txtServiceChgs.Text);
            }

            if (txtUtilitiesFees.Text.Trim() != "")
            {
                dMonthlyRentLbl5 = Convert.ToDouble(txtUtilitiesFees.Text);
            }

            if (txtSignageFees.Text.Trim() != "")
            {
                dMonthlyRentLbl6 = Convert.ToDouble(txtSignageFees.Text);
            }


            if (txtOtherFeesValue1.Text.Trim() != "")
            {
                dMonthlyRentLbl7 = Convert.ToDouble(txtOtherFeesValue1.Text);
            }

            //	if (ddlOtherFees1.SelectedItem.Text != "Select Other Fee")
            //	{
            //		dMonthlyRentLbl7 = Convert.ToDouble(ddlOtherFees1.SelectedItem.Text);
            //	}

            //end


            // CalculateContractValue();  
            if (rdoTypeOption2.Checked)
            {
                //end ph2
                //ph2 claculate tenure total in months 

                //ph2 check total tenure amount
                // checktenuretotalamtmessage();

            }

            //end


            if (currentRow.RowIndex == 0)
            {
                DateTimeControl dSD = (DateTimeControl)currentRow.Cells[1].FindControl("TenancyStartDate");
                int iDays = DateTime.DaysInMonth(dSD.SelectedDate.Year, dSD.SelectedDate.Month);
                if (dSD.SelectedDate.Day != 1)
                {
                    int iBalDays = iDays - dSD.SelectedDate.Day + 1;
                    double dBalanceDays = (double)iBalDays / (double)iDays;
                    lbltempbalancedaysFirst.Text = Convert.ToString(dBalanceDays); // ph2 for refresh
                    lblFirstRentNotes.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRent, 2) + ". ";
                    //ph2 
                    lblFirstMonthlyRent1.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl1, 2) + ". ";
                    lblFirstMonthlyRent2.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl2, 2) + ". ";
                    lblFirstMonthlyRent3.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl3, 2) + ". ";
                    lblFirstMonthlyRent4.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl4, 2) + ". ";
                    lblFirstMonthlyRent5.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl5, 2) + ". ";
                    lblFirstMonthlyRent6.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl6, 2) + ". ";
                    lblFirstMonthlyRent7.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl7, 2) + ". ";

                    //end ph2

                    Label lblLabel1 = (Label)currentRow.Cells[6].FindControl("lblFirstRent");
                    lblLabel1.Text = Convert.ToString(Math.Round(dBalanceDays * dMonthlyRent, 2));

                }
            }

            if (currentRow.RowIndex == grvTenantDetails.Rows.Count - 1)
            {
                DateTimeControl dED = (DateTimeControl)currentRow.Cells[2].FindControl("TenancyEndDate");
                int iDays = DateTime.DaysInMonth(dED.SelectedDate.Year, dED.SelectedDate.Month);
                if (dED.SelectedDate.Day != iDays)
                {
                    int iBalDays = dED.SelectedDate.Day;
                    double dBalanceDays = (double)iBalDays / (double)iDays;
                    lbltempbalancedaysLast.Text = Convert.ToString(dBalanceDays); // ph2 for refresh
                    lblLastRentNotes.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRent, 2) + ". ";
                    //ph2

                    lblLastMonthlyRent1.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl1, 2) + ". ";
                    lblLastMonthlyRent2.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl2, 2) + ". ";
                    lblLastMonthlyRent3.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl3, 2) + ". ";
                    lblLastMonthlyRent4.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl4, 2) + ". ";
                    lblLastMonthlyRent5.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl5, 2) + ". ";
                    lblLastMonthlyRent6.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl6, 2) + ". ";
                    lblLastMonthlyRent7.Text = "Last Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRentLbl7, 2) + ". ";

                    //end ph2

                    Label lblLabel2 = (Label)currentRow.Cells[6].FindControl("lblLastRent");
                    lblLabel2.Text = Convert.ToString(Math.Round(dBalanceDays * dMonthlyRent, 2));
                }
            }
        }

        bool ValidateLicenseDates()
        {
            lblErrorMsg.Text = "";

            DateTime dStart = DateTime.Today;
            DateTime dEnd = DateTime.Today;
            DateTime dSelectedDate = DateTime.Today;
            //int iCurrRow;

            //validate tenure with license dates...
            DateTime dtLastEndDate = DateTime.Today;
            DateTime dtCalculatedEndDate = DateTime.Today;
            DateTime dtFirstStartDate = DateTime.Today;
            int iTenureYears = 0;
            int iTenureMonths = 0;
            int iTenureDays = 0;


            if (txtTenureDay.Text.Trim() != string.Empty)
            {
                iTenureDays = Convert.ToInt32(txtTenureDay.Text.Trim());
            }


            if (txtTenureMonth.Text.Trim() != string.Empty)
            {
                iTenureMonths = Convert.ToInt32(txtTenureMonth.Text.Trim());
            }

            if (txtTenureYear.Text.Trim() != string.Empty)
            {
                iTenureYears = Convert.ToInt32(txtTenureYear.Text.Trim());
            }

            DataTable dt = null;
            if (ViewState["dtIQMonthlyRent"] != null)
            {
                dt = (DataTable)ViewState["dtIQMonthlyRent"];
                if (dt == null)
                    initiateMonthlyRentDT(dt);
            }
            else
            {
                dt = initiateMonthlyRentDT(dt);
                ViewState["dtIQMonthlyRent"] = dt;
            }
            dt = (DataTable)ViewState["dtIQMonthlyRent"];
            int iRowindex = 0;
            int iLoopindex = 0;
            foreach (DataRow row in dt.Rows)
            {
                iRowindex = iRowindex + 1;
                iLoopindex = 0;
                if (row["StartDate"].ToString() == string.Empty)
                {
                    lblErrorMsg.Text = "Tenancy Start Date cannot be empty. Please select Tenancy Start Date.";
                    return false;
                }
                dSelectedDate = DateTime.ParseExact(row["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);

                if (dtFirstStartDate.Date == DateTime.Today.Date)
                {
                    dtFirstStartDate = dSelectedDate.Date;
                    dtCalculatedEndDate = dtFirstStartDate;
                }
                dtLastEndDate = DateTime.ParseExact(row["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);

                foreach (DataRow oLoopRow in dt.Rows)
                {
                    iLoopindex = iLoopindex + 1;
                    if (iLoopindex == iRowindex)
                    {
                        continue;
                    }

                    if (oLoopRow["StartDate"].ToString() == string.Empty)
                    {
                        lblErrorMsg.Text = "Tenancy Start Date cannot be empty. Please select Tenancy Start Date.";
                        return false;
                    }

                    if (oLoopRow["EndDate"].ToString() == string.Empty)
                    {
                        lblErrorMsg.Text = "Tenancy End Date cannot be empty. Please select Tenancy End Date.";
                        return false;
                    }

                    dStart = DateTime.ParseExact(oLoopRow["StartDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);
                    dEnd = DateTime.ParseExact(oLoopRow["EndDate"].ToString(), "dd/MM/yyyy", CultureInfo.InvariantCulture);

                    if ((dStart != null) && (dEnd != null))
                    {
                        if (dSelectedDate.Date >= dStart.Date && dSelectedDate.Date <= dEnd.Date)
                        {
                            lblErrorMsg.Text = "The Tenancy/Licence Start dates cannot overlap. Please re-enter the dates.";
                            return false;
                        }
                    }
                }
            }

            //validate license dates with tenure period...
            dtCalculatedEndDate = dtCalculatedEndDate.AddYears(iTenureYears);
            dtCalculatedEndDate = dtCalculatedEndDate.AddMonths(iTenureMonths);
            dtCalculatedEndDate = dtCalculatedEndDate.AddDays(iTenureDays);
            dtCalculatedEndDate = dtCalculatedEndDate.AddDays(-1);
            if (dtCalculatedEndDate.Date != dtLastEndDate.Date)
            {
                lblErrorMsg.Text = "The Tenure does not match to the License Dates. Kindly recheck and enter correct license dates.";
                dtCalculatedEndDate = DateTime.Today;
                dtFirstStartDate = DateTime.Today;
                return false;
            }


            return true;
        }


        // PH2 to refresh the firat and last month rentals


        public void refresh()
        {

            double dMonthlyRentLbl1 = 0.00;
            double dMonthlyRentLbl2 = 0.00;
            double dMonthlyRentLbl3 = 0.00;
            double dMonthlyRentLbl4 = 0.00;
            double dMonthlyRentLbl5 = 0.00;
            double dMonthlyRentLbl6 = 0.00;
            double dMonthlyRentLbl7 = 0.00;
            double dBalanceDaysFirst = 0.00;
            double dBalanceDaysLast = 0.00;

            // validations 


            if (lbltempbalancedaysFirst.Text == string.Empty)
            {
                //lbltotaltenuremonths.Text = "Please update monthly rent to refesh";
                //return;
                lbltotaltenuremonths.Text = "0";
                // return
            }
            if (lbltempbalancedaysLast.Text == string.Empty)
            {
                // lbltotaltenuremonths.Text = "Please update monthly rent to refesh";
                //return;
                lbltotaltenuremonths.Text = "0";

            }

            lbltotaltenuremonths.Text = "";
            if (lbltempbalancedaysFirst.Text.Trim() != "")
            {
                dBalanceDaysFirst = Convert.ToDouble(lbltempbalancedaysFirst.Text);
            }
            if (lbltempbalancedaysLast.Text.Trim() != "")
            {
                dBalanceDaysLast = Convert.ToDouble(lbltempbalancedaysLast.Text);
            }

            if (txtSecurityAmt.Text.Trim() != "")
            {
                dMonthlyRentLbl1 = Convert.ToDouble(txtSecurityAmt.Text);
            }

            if (txtUtilitiesDeposit.Text.Trim() != "")
            {
                dMonthlyRentLbl2 = Convert.ToDouble(txtUtilitiesDeposit.Text);
            }

            if (txtFittingDeposit.Text.Trim() != "")
            {
                dMonthlyRentLbl3 = Convert.ToDouble(txtFittingDeposit.Text);
            }

            if (txtServiceChgs.Text.Trim() != "")
            {
                dMonthlyRentLbl4 = Convert.ToDouble(txtServiceChgs.Text);
            }

            if (txtUtilitiesFees.Text.Trim() != "")
            {
                dMonthlyRentLbl5 = Convert.ToDouble(txtUtilitiesFees.Text);
            }

            if (txtSignageFees.Text.Trim() != "")
            {
                dMonthlyRentLbl6 = Convert.ToDouble(txtSignageFees.Text);
            }




            if (txtOtherFeesValue1.Text != "")
            {
                dMonthlyRentLbl7 = Convert.ToDouble(txtOtherFeesValue1.Text);
            }


            // lblFirstRentNotes.Text = "First Billing Amount: $" + Math.Round(dBalanceDays * dMonthlyRent, 2) + ". ";
            //ph2 
            lblFirstMonthlyRent1.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl1, 2) + ". ";
            lblFirstMonthlyRent2.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl2, 2) + ". ";
            lblFirstMonthlyRent3.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl3, 2) + ". ";
            lblFirstMonthlyRent4.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl4, 2) + ". ";
            lblFirstMonthlyRent5.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl5, 2) + ". ";
            lblFirstMonthlyRent6.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl6, 2) + ". ";
            lblFirstMonthlyRent7.Text = "First Billing Amount: $" + Math.Round(dBalanceDaysFirst * dMonthlyRentLbl7, 2) + ". ";






            lblLastMonthlyRent1.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl1, 2) + ". ";
            lblLastMonthlyRent2.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl2, 2) + ". ";
            lblLastMonthlyRent3.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl3, 2) + ". ";
            lblLastMonthlyRent4.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl4, 2) + ". ";
            lblLastMonthlyRent5.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl5, 2) + ". ";
            lblLastMonthlyRent6.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl6, 2) + ". ";
            lblLastMonthlyRent7.Text = "Last Billing Amount: $" + Math.Round(dBalanceDaysLast * dMonthlyRentLbl7, 2) + ". ";


        }

        // end code 




        protected void Refresh_CheckedChanged(object sender, EventArgs e)
        {
            refresh();
        }
        protected void UpdateValues_Click(object sender, EventArgs e)
        {
            refresh();
        }
        protected void rdovariablelatepayment_CheckedChanged(object sender, EventArgs e)
        {

            getprevalingIntRate();



        }

        // END


        // PH2 

        public void getprevalingIntRate()
        {
            using (SPWeb web = site.OpenWeb())
            {


                // new code

                SPList TCode = web.Lists[strGeneralSettings];

                SPQuery qry1 = new SPQuery();

                //	qry1.Query = string.Format("<Where><Eq><FieldRef Name='Category' /><Value Type='Choice'>PrevalingIntrestRate</Value></Eq></Where>");

                qry1.Query = string.Format("<Where><Eq><FieldRef Name='Category' /><Value Type='Choice'>PrevailingInterestRate</Value></Eq></Where>");  //updated after code intigration

                SPListItemCollection items1 = TCode.GetItems(qry1);

                string sconfigvalue = "";

                foreach (SPListItem item in items1)
                {
                    if (item["ConfigValue"].ToString() != null)
                    {
                        sconfigvalue = item["ConfigValue"].ToString();
                        txtLatePayment.Text = sconfigvalue;
                        txtLatePayment.Enabled = false;
                    }

                }

                // end new code			
            }
        }
        protected void rdofixedlatepayment_CheckedChanged(object sender, EventArgs e)
        {
            txtLatePayment.Text = "";
            txtLatePayment.Enabled = true;
        }
        protected void rdoVarUtility_CheckedChanged(object sender, EventArgs e)
        {

        }
        protected void txtContractValue_TextChanged(object sender, EventArgs e)
        {
            string check = "";
            lblrenewmessage.Text = "";


            if (rdoTypeOption1.Checked)
            {
                check = "N";
            }
            if (rdoTypeOption2.Checked)
            {
                check = "Y";
            }
            if (rdoTypeOption3.Checked)
            {
                check = "N";
            }

            if (check == "Y")
            {

                SPWeb web = site.OpenWeb();
                SPList TAList = web.Lists[strAgreementListName];
                //	SPListItem recordItem = TAList.GetItemById(iRecord);

                String PrevTRno = "";

                double prevamt = 0;
                double useramt = 0;

                useramt = Convert.ToDouble(lbltotaltenurevalue.Text);


                SPQuery qry1 = new SPQuery();

                qry1.Query = string.Format("<Where><Eq><FieldRef Name='TenancyRecordNumber' /><Value Type='Text'>" + lblRecordNumber.Text + "</Value></Eq></Where>");


                SPListItemCollection items1 = TAList.GetItems(qry1);


                foreach (SPListItem item in items1)
                {
                    if (item["TenancyRecordNumberOld"].ToString() != null)
                    {
                        PrevTRno = item["TenancyRecordNumberOld"].ToString();

                    }

                }


                SPQuery qry = new SPQuery();

                qry.Query = string.Format("<Where><Eq><FieldRef Name='TenancyRecordNumber' /><Value Type='Text'>" + PrevTRno + "</Value></Eq></Where>");


                SPListItemCollection items = TAList.GetItems(qry);

                // SPListItemCollection items = TAList.GetItems("Title", "TenancyRecordNumber", );

                //  SPListItem it = null;
                foreach (SPListItem item in items)
                {
                    if (item["TotalContractValue"].ToString() != null)
                    {
                        prevamt = Convert.ToDouble(item["TotalContractValue"].ToString());

                    }

                }

                if (useramt != prevamt)
                {
                    // string msg = "Please take approval from Business Development team by fill in the form: [link to the form -> " + "<a href='http://sgehmoss01:23688'>http://sgehmoss01:23688</a>" + "]";
                    string msg = "Please take approval from Business Development team";
                    lblrenewmessage.Text = msg;
                }
                else
                {
                    lblrenewmessage.Text = "";
                }

            }

        }


        //ph2 draft

        protected void btnDraft_Click(object sender, EventArgs e)
        {


            drpAgreementStatus.SelectedItem.Text = "Draft";

            string sDate1 = DateTime.Today.Date.ToString("dd/MM/yyyy");
            lblErrorMsg.Text = "";
            Regex rTelCheck = new Regex("^[0-9]+$");
            Regex rAmount = new Regex("^[0-9]+([.,][0-9]{1,2})?$");

            try
            {
                SPWeb web = null;
                SPListItem Item;
                int iProcess = 0;

                SPSecurity.RunWithElevatedPrivileges(delegate ()
                {
                    web = site.OpenWeb();
                    // Page.Validate();
                });



                SPList TAList;

                // ph2 chnages chnage new number

                string recordno = lblRecordNumber.Text;
                string subrecordno = recordno.Substring(0, 5);
                string dflag = "";
                if (subrecordno == "Draft")
                {
                    dflag = "Yes";
                }


                // submitted document

                if ((drpAgreementStatus.SelectedItem.Text == "Draft") && (dflag != "Yes"))
                {
                    // btnDraft.Visible = false;
                    lblTest.Text = "Draft is not allowed";

                    return;
                }


                TAList = web.Lists[strAgreementListNameDraft];


                if (!bEdit)
                {



                    if ((drpAgreementStatus.SelectedItem.Text != "Draft") && (mRecord == "Draft"))
                    {
                        lblTest.Text = "Please select Status as Draft";

                        return;

                    }
                    TAList = web.Lists[strAgreementListNameDraft];
                    Item = TAList.Items.Add(); // for new documents

                }
                else
                {


                    Item = TAList.GetItemById(iRecord);


                    //end ph2
                }

                if (!ValidateLicenseDates())
                {
                    return;
                }

                UpdateAuditTrail("CCName", ddlCCName.SelectedValue, Item, Item.Fields.GetFieldByInternalName("CCName"));

                //ph2 draft
                if (ddlCCName.SelectedItem.Text == "Select CC Name") // ph2 for draft
                {
                    Item["CCName"] = "000";

                    iCCID = 000;
                }
                else
                {
                    Item["CCName"] = ddlCCName.SelectedValue;

                    iCCID = Convert.ToInt32(ddlCCName.SelectedValue);
                }


                //end ph2

                UpdateAuditTrail("AgreementStatus", drpAgreementStatus.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("AgreementStatus"));
                Item["AgreementStatus"] = drpAgreementStatus.SelectedItem.Text;
                //Item["AgreementStatus"] = "Submit for Approval";

                //ph2 update resubmission date

                if (drpAgreementStatus.SelectedItem.Text == "ReSubmission")
                {
                    UpdateAuditTrail("ResubmissionDate", sDate1, Item, Item.Fields.GetFieldByInternalName("ResubmissionDate"));

                    Item["ResubmissionDate"] = DateTime.Today.Date;


                }

                //end ph2

                UpdateAuditTrail("ApprovalOfAward", lblApprovingAuthority.Text, Item, Item.Fields.GetFieldByInternalName("ApprovalOfAward"));
                Item["ApprovalOfAward"] = lblApprovingAuthority.Text;

                if (txtContractValue.Text.Trim() != "")
                {
                    //if (rAmount.IsMatch(txtContractValue.Text.Trim()))
                    //{
                    UpdateAuditTrail("TotalContractValue", txtContractValue.Text, Item, Item.Fields.GetFieldByInternalName("TotalContractValue"));
                    Item["TotalContractValue"] = Convert.ToDouble(txtContractValue.Text);
                    //}
                    //else
                    //{
                    //	lblErrorMsg.Text = "Total Contract Value field should contain only numbers.";
                    //	return;
                    // }
                }
                else
                {
                    Item["TotalContractValue"] = "0.00";
                }

                //ph2 chnages total tenure value in months


                if (lbltotaltenuremonths.Text.Trim() != "")
                {
                    UpdateAuditTrail("totaltenuremonths", lbltotaltenuremonths.Text, Item, Item.Fields.GetFieldByInternalName("totaltenuremonths"));
                    Item["totaltenuremonths"] = Convert.ToDouble(lbltotaltenuremonths.Text);


                }
                else
                {
                    Item["totaltenuremonths"] = "0.00";
                }
                if (lbltotaltenurevalue.Text.Trim() != "")
                {
                    UpdateAuditTrail("totaltenurevalue", lbltotaltenurevalue.Text, Item, Item.Fields.GetFieldByInternalName("totaltenurevalue"));
                    Item["totaltenurevalue"] = Convert.ToDouble(lbltotaltenurevalue.Text);


                }
                else
                {
                    Item["totaltenurevalue"] = "0.00";
                }

                // update renewal monthly rent

                if (lblRenewalMonthlyRent.Text != "")
                {
                    UpdateAuditTrail("RenewalMonthlyRent", lblRenewalMonthlyRent.Text, Item, Item.Fields.GetFieldByInternalName("RenewalMonthlyRent"));
                    Item["RenewalMonthlyRent"] = lblRenewalMonthlyRent.Text;


                }
                else
                {
                    Item["RenewalMonthlyRent"] = "0.00";
                }

                UpdateAuditTrail("ApprovalofAwardDate", dtApprovalDate.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("ApprovalofAwardDate"));
                Item["ApprovalofAwardDate"] = dtApprovalDate.SelectedDate;

                //sunil...
                string sSelectedUnits = "";
                foreach (int i in lbxUnitNumber.GetSelectedIndices())
                {
                    sSelectedUnits = sSelectedUnits + lbxUnitNumber.Items[i].Value + ",";
                }
                UpdateAuditTrail("CCUnitNumber", sSelectedUnits, Item, Item.Fields.GetFieldByInternalName("CCUnitNumber"));
                Item["CCUnitNumber"] = sSelectedUnits;

                if (!dtEarlyTerminationDate.IsDateEmpty)
                {
                    UpdateAuditTrail("EarlyTerminationDate", dtEarlyTerminationDate.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("EarlyTerminationDate"));
                    Item["EarlyTerminationDate"] = dtEarlyTerminationDate.SelectedDate;
                }
                else
                {
                    UpdateAuditTrail("EarlyTerminationDate", "", Item, Item.Fields.GetFieldByInternalName("EarlyTerminationDate"));
                    Item["EarlyTerminationDate"] = null;
                }

                if (txtEmail.Text.Trim() != "")
                {
                    UpdateAuditTrail("EmailAddress", txtEmail.Text, Item, Item.Fields.GetFieldByInternalName("EmailAddress"));
                    Item["EmailAddress"] = txtEmail.Text;
                }
                else
                {
                    Item["EmailAddress"] = "";
                }


                if (txtFittingDeposit.Text.Trim() != "")
                {
                    if (rAmount.IsMatch(txtFittingDeposit.Text.Trim()))
                    {
                        UpdateAuditTrail("FittingOutDeposit", txtFittingDeposit.Text, Item, Item.Fields.GetFieldByInternalName("FittingOutDeposit"));
                        Item["FittingOutDeposit"] = Convert.ToDouble(txtFittingDeposit.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Fitting Out Deposit field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["FittingOutDeposit"] = "0.00";
                }


                if (!dtFittingFrom.IsDateEmpty)
                {
                    UpdateAuditTrail("FittingOutPeriodFrom", dtFittingFrom.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodFrom"));
                    Item["FittingOutPeriodFrom"] = dtFittingFrom.SelectedDate;
                }
                else
                {
                    UpdateAuditTrail("FittingOutPeriodFrom", "", Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodFrom"));
                    Item["FittingOutPeriodFrom"] = null;
                }


                if (!dtFittingTo.IsDateEmpty)
                {
                    UpdateAuditTrail("FittingOutPeriodTo", dtFittingTo.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodTo"));
                    Item["FittingOutPeriodTo"] = dtFittingTo.SelectedDate;
                }
                else
                {
                    UpdateAuditTrail("FittingOutPeriodTo", "", Item, Item.Fields.GetFieldByInternalName("FittingOutPeriodTo"));
                    Item["FittingOutPeriodTo"] = null;
                }




                UpdateAuditTrail("FloorArea", lblSQFT.Text, Item, Item.Fields.GetFieldByInternalName("FloorArea"));
                Item["FloorArea"] = lblSQFT.Text;

                UpdateAuditTrail("GracePeriod", ddlGracePeriod.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("GracePeriod"));
                Item["GracePeriod"] = ddlGracePeriod.SelectedItem.Text;




                if (rdoHalalCertYes.Checked)
                {
                    UpdateAuditTrail("HalalCertification", "Yes", Item, Item.Fields.GetFieldByInternalName("HalalCertification"));
                    Item["HalalCertification"] = true;
                }
                else
                {
                    UpdateAuditTrail("HalalCertification", "No", Item, Item.Fields.GetFieldByInternalName("HalalCertification"));
                    Item["HalalCertification"] = false;
                }

                if (txtPhoneNumber.Text.Trim() != "")
                {
                    if (rTelCheck.IsMatch(txtPhoneNumber.Text.Trim()))
                    {
                        UpdateAuditTrail("HandPhoneNumber", txtPhoneNumber.Text, Item, Item.Fields.GetFieldByInternalName("HandPhoneNumber"));
                        Item["HandPhoneNumber"] = txtPhoneNumber.Text;
                    }
                    else
                    {
                        lblErrorMsg.Text = "Hand Phone Number should contain only numbers.";
                        return;
                    }
                }

                UpdateAuditTrail("IDNumber", txtFIN.Text, Item, Item.Fields.GetFieldByInternalName("IDNumber"));
                Item["IDNumber"] = txtFIN.Text;


                if (txtLatePayment.Text.Trim() != "")
                {
                    if (rAmount.IsMatch(txtLatePayment.Text.Trim()))
                    {
                        UpdateAuditTrail("LatePaymentInterestRate", txtLatePayment.Text, Item, Item.Fields.GetFieldByInternalName("LatePaymentInterestRate"));
                        Item["LatePaymentInterestRate"] = Convert.ToDouble(txtLatePayment.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Late Payment Interest Rate field should contain only numbers.";
                        return;
                    }
                }

                if (rdoTerm1.Checked)
                {
                    UpdateAuditTrail("LicenseTerm", "First", Item, Item.Fields.GetFieldByInternalName("LicenseTerm"));
                    Item["LicenseTerm"] = "First";
                }

                if (rdoTerm2.Checked)
                {
                    UpdateAuditTrail("LicenseTerm", "Second", Item, Item.Fields.GetFieldByInternalName("LicenseTerm"));
                    Item["LicenseTerm"] = "Second";
                }

                if (rdoTerm3.Checked)
                {
                    UpdateAuditTrail("LicenseTerm", "Third", Item, Item.Fields.GetFieldByInternalName("LicenseTerm"));
                    Item["LicenseTerm"] = "Third";
                }

                if (txtOffNumber.Text.Trim() != "")
                {
                    if (rTelCheck.IsMatch(txtOffNumber.Text.Trim()))
                    {
                        UpdateAuditTrail("OfficeNumber", txtOffNumber.Text.Trim(), Item, Item.Fields.GetFieldByInternalName("OfficeNumber"));
                        Item["OfficeNumber"] = txtOffNumber.Text.Trim();
                    }
                    else
                    {
                        lblErrorMsg.Text = "Office Number should contain only numbers.";
                        return;
                    }
                }


                //ph2 start

                // ph2 chnages on 15/04/2017	




                if (txtOtherFeesValue1.Text.Trim() != "")
                {
                    if (rAmount.IsMatch(txtOtherFeesValue1.Text.Trim()))
                    {
                        UpdateAuditTrail("OtherFeesValue1", txtOtherFeesValue1.Text, Item, Item.Fields.GetFieldByInternalName("OtherFeesValue1"));
                        Item["OtherFeesValue1"] = Convert.ToDouble(txtOtherFeesValue1.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Other Fee Values 1 field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["OtherFeesValue1"] = "0.00";
                }

                if (txtOtherFeesValue2.Text.Trim() != "")
                {
                    if (rAmount.IsMatch(txtOtherFeesValue2.Text.Trim()))
                    {
                        UpdateAuditTrail("OtherFeesValue2", txtOtherFeesValue2.Text, Item, Item.Fields.GetFieldByInternalName("OtherFeesValue2"));
                        Item["OtherFeesValue2"] = Convert.ToDouble(txtOtherFeesValue2.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Other Fee Values 2 field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["OtherFeesValue2"] = "0.00";
                }


                UpdateAuditTrail("OtherFees1", ddlOtherFees1.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("OtherFees1"));
                Item["OtherFees1"] = ddlOtherFees1.SelectedItem.Text;

                UpdateAuditTrail("OtherFees2", ddlOtherFees2.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("OtherFees2"));
                Item["OtherFees2"] = ddlOtherFees2.SelectedItem.Text;
                // ph2 end

                UpdateAuditTrail("PersonInCharge", txtPersonInCharge.Text, Item, Item.Fields.GetFieldByInternalName("PersonInCharge"));
                Item["PersonInCharge"] = txtPersonInCharge.Text;


                UpdateAuditTrail("ReasonForEarlyTermination", txtReason.Text, Item, Item.Fields.GetFieldByInternalName("ReasonForEarlyTermination"));
                Item["ReasonForEarlyTermination"] = txtReason.Text;

                UpdateAuditTrail("RegisteredAddress", txtRegisteredAdd.Text, Item, Item.Fields.GetFieldByInternalName("RegisteredAddress"));
                Item["RegisteredAddress"] = txtRegisteredAdd.Text;

                UpdateAuditTrail("Remarks", txtRemarks.Text, Item, Item.Fields.GetFieldByInternalName("Remarks"));
                Item["Remarks"] = txtRemarks.Text;

                string sRenewal = txtRenewalYear.Text + "-" + txtRenewalMonth.Text + "-" + txtRenewalDay.Text;
                UpdateAuditTrail("RenewalPeriod", sRenewal, Item, Item.Fields.GetFieldByInternalName("RenewalPeriod"));
                Item["RenewalPeriod"] = sRenewal;

                string sRenewal2 = txtRenewalYear2.Text + "-" + txtRenewalMonth2.Text + "-" + txtRenewalDay2.Text;
                UpdateAuditTrail("RenewalPeriod2", sRenewal, Item, Item.Fields.GetFieldByInternalName("RenewalPeriod2"));
                Item["RenewalPeriod2"] = sRenewal2;

                UpdateAuditTrail("RentalDueDate", ddlRentalDueDate.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("RentalDueDate"));
                Item["RentalDueDate"] = ddlRentalDueDate.SelectedItem.Text;

                UpdateAuditTrail("ROCUEN", txtROCNumber.Text, Item, Item.Fields.GetFieldByInternalName("ROCUEN"));
                Item["ROCUEN"] = txtROCNumber.Text;

                if (chkCash.Checked)
                {
                    UpdateAuditTrail("SecurityDeposit", "Cash", Item, Item.Fields.GetFieldByInternalName("SecurityDeposit"));
                    Item["SecurityDeposit"] = "Cash";
                }
                if (chkBankGurantee.Checked)
                {
                    UpdateAuditTrail("SecurityDeposit", "BG", Item, Item.Fields.GetFieldByInternalName("SecurityDeposit"));
                    Item["SecurityDeposit"] = "BG";
                }

                if (txtSecurityAmt.Text != "")
                {
                    if (rAmount.IsMatch(txtSecurityAmt.Text.Trim()))
                    {
                        UpdateAuditTrail("SecurityDepositAmount", txtSecurityAmt.Text, Item, Item.Fields.GetFieldByInternalName("SecurityDepositAmount"));
                        Item["SecurityDepositAmount"] = Convert.ToDouble(txtSecurityAmt.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Security Deposit Amount field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["SecurityDepositAmount"] = "0.00";
                }

                if (txtServiceChgs.Text.Trim() != "")
                {
                    if (rAmount.IsMatch(txtServiceChgs.Text.Trim()))
                    {
                        UpdateAuditTrail("ServiceCharges", txtServiceChgs.Text, Item, Item.Fields.GetFieldByInternalName("ServiceCharges"));
                        Item["ServiceCharges"] = Convert.ToDouble(txtServiceChgs.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Service & Conservancy Charges field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["ServiceCharges"] = "0.00";
                }

                if (txtSignageFees.Text.Trim() != "")
                {
                    if (rAmount.IsMatch(txtSignageFees.Text.Trim()))
                    {
                        UpdateAuditTrail("SignageFees", txtSignageFees.Text, Item, Item.Fields.GetFieldByInternalName("SignageFees"));
                        Item["SignageFees"] = Convert.ToDouble(txtSignageFees.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Signage Fees field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["SignageFees"] = "0.00";
                }




                if (rdoSpace1.Checked)
                {
                    UpdateAuditTrail("SpaceClassification", "Commercial", Item, Item.Fields.GetFieldByInternalName("SpaceClassification"));
                    Item["SpaceClassification"] = "Commercial";
                }

                if (rdoSpace2.Checked)
                {
                    UpdateAuditTrail("SpaceClassification", "C & CI", Item, Item.Fields.GetFieldByInternalName("SpaceClassification"));
                    Item["SpaceClassification"] = "C & CI";
                }

                if (rdoSpace3.Checked)
                {
                    UpdateAuditTrail("SpaceClassification", "Utility", Item, Item.Fields.GetFieldByInternalName("SpaceClassification"));
                    Item["SpaceClassification"] = "Utility";
                }

                if (!dtStampDutyDate.IsDateEmpty)
                {
                    UpdateAuditTrail("StampDutyFilingDate", dtStampDutyDate.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("StampDutyFilingDate"));
                    Item["StampDutyFilingDate"] = dtStampDutyDate.SelectedDate;
                }
                else
                {
                    UpdateAuditTrail("StampDutyFilingDate", "", Item, Item.Fields.GetFieldByInternalName("StampDutyFilingDate"));
                    Item["StampDutyFilingDate"] = null;
                }




                if (rdoFixedUtility.Checked)
                {
                    UpdateAuditTrail("UtilityFixedVar", "Fixed", Item, Item.Fields.GetFieldByInternalName("UtilityFixedVar"));
                    Item["UtilityFixedVar"] = "Fixed";
                }

                if (rdoVarUtility.Checked)
                {
                    UpdateAuditTrail("UtilityFixedVar", "Variable", Item, Item.Fields.GetFieldByInternalName("UtilityFixedVar"));
                    Item["UtilityFixedVar"] = "Variable";
                }

                //ph2 

                if (rdodirectUtility.Checked)
                {
                    UpdateAuditTrail("UtilityFixedVar", "Direct", Item, Item.Fields.GetFieldByInternalName("UtilityFixedVar"));
                    Item["UtilityFixedVar"] = "Direct";
                }

                //end ph2

                if (txtUtilitiesFees.Text != "")
                {
                    if (rdoFixedUtility.Checked)
                    {

                        if (rAmount.IsMatch(txtUtilitiesFees.Text.Trim()))
                        {
                            UpdateAuditTrail("UtilitiesFees", txtUtilitiesFees.Text, Item, Item.Fields.GetFieldByInternalName("UtilitiesFees"));
                            Item["UtilitiesFees"] = Convert.ToDouble(txtUtilitiesFees.Text);
                        }
                        else
                        {
                            lblErrorMsg.Text = "Utilities Fees field should contain only numbers.";
                            return;
                        }
                    }
                    else
                    {
                        Item["UtilitiesFees"] = "0.00";
                    }
                }
                else
                {
                    Item["UtilitiesFees"] = "0.00";
                }



                if (!dtSuspensionFrom.IsDateEmpty)
                {
                    UpdateAuditTrail("SuspensionDateFrom", dtSuspensionFrom.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("SuspensionDateFrom"));
                    Item["SuspensionDateFrom"] = dtSuspensionFrom.SelectedDate;
                }
                else
                {
                    UpdateAuditTrail("SuspensionDateFrom", "", Item, Item.Fields.GetFieldByInternalName("SuspensionDateFrom"));
                    Item["SuspensionDateFrom"] = null;
                }


                if (!dtSuspensionTo.IsDateEmpty)
                {
                    UpdateAuditTrail("SuspensionDateTo", dtSuspensionTo.SelectedDate.ToString(), Item, Item.Fields.GetFieldByInternalName("SuspensionDateTo"));
                    Item["SuspensionDateTo"] = dtSuspensionTo.SelectedDate;
                }
                else
                {
                    UpdateAuditTrail("SuspensionDateTo", "", Item, Item.Fields.GetFieldByInternalName("SuspensionDateTo"));
                    Item["SuspensionDateTo"] = null;

                }

                UpdateAuditTrail("TenancyRecordNumber", lblRecordNumber.Text, Item, Item.Fields.GetFieldByInternalName("TenancyRecordNumber"));
                Item["TenancyRecordNumber"] = lblRecordNumber.Text;

                //ph2 update previous tenenacy record - Renewal and Novation

                UpdateAuditTrail("TenancyRecordNumberOld", lblPrevRecordNumber.Text, Item, Item.Fields.GetFieldByInternalName("TenancyRecordNumberOld"));
                Item["TenancyRecordNumberOld"] = lblPrevRecordNumber.Text;




                //ph2 changes disabled

                UpdateAuditTrail("TenantName", ddlTenantName.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("TenantName"));
                Item["TenantName"] = ddlTenantName.SelectedItem.Text;

                // end SK

                UpdateAuditTrail("TenantTradingName", txtTradingName.Text, Item, Item.Fields.GetFieldByInternalName("TenantTradingName"));
                Item["TenantTradingName"] = txtTradingName.Text.ToUpper();

                string sTenure = txtTenureYear.Text + "-" + txtTenureMonth.Text + "-" + txtTenureDay.Text;
                UpdateAuditTrail("Tenure", sTenure, Item, Item.Fields.GetFieldByInternalName("Tenure"));
                Item["Tenure"] = sTenure;


                UpdateAuditTrail("TradeCategory", ddlTradeCat.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("TradeCategory"));
                Item["TradeCategory"] = ddlTradeCat.SelectedItem.Text;

                if (rdoTypeOption1.Checked)
                {
                    UpdateAuditTrail("TenancyRecordType", "New", Item, Item.Fields.GetFieldByInternalName("TenancyRecordType"));
                    Item["TenancyRecordType"] = "New";
                }
                if (rdoTypeOption2.Checked)
                {
                    UpdateAuditTrail("TenancyRecordType", "Renewal", Item, Item.Fields.GetFieldByInternalName("TenancyRecordType"));
                    Item["TenancyRecordType"] = "Renewal";
                }
                if (rdoTypeOption3.Checked)
                {
                    UpdateAuditTrail("TenancyRecordType", "Extension", Item, Item.Fields.GetFieldByInternalName("TenancyRecordType"));
                    Item["TenancyRecordType"] = "Extension";
                }


                //added by SK for new text field type from ddl to text
                UpdateAuditTrail("TypeOfCompany", txtCompanyType.Text, Item, Item.Fields.GetFieldByInternalName("TypeOfCompany"));
                Item["TypeOfCompany"] = txtCompanyType.Text;
                //end

                UpdateAuditTrail("TypeOfTrade", ddlTradeType.SelectedItem.Text, Item, Item.Fields.GetFieldByInternalName("TypeOfTrade"));
                Item["TypeOfTrade"] = ddlTradeType.SelectedItem.Text;

                if (rdoUnitOption1.Checked)
                {
                    UpdateAuditTrail("UnitType", "Single", Item, Item.Fields.GetFieldByInternalName("UnitType"));
                    Item["UnitType"] = "Single";
                }

                if (rdoUnitOption2.Checked)
                {
                    UpdateAuditTrail("UnitType", "Multiple Units", Item, Item.Fields.GetFieldByInternalName("UnitType"));
                    Item["UnitType"] = "Multiple Units";
                }

                //ph2 changes

                if (rdopaymentoption1.Checked)
                {
                    UpdateAuditTrail("PaymentOption", "Monthly", Item, Item.Fields.GetFieldByInternalName("PaymentOption"));
                    Item["PaymentOption"] = "Monthly";
                }

                if (rdopaymentoption2.Checked)
                {
                    UpdateAuditTrail("PaymentOption", "LumpSum", Item, Item.Fields.GetFieldByInternalName("PaymentOption"));
                    Item["PaymentOption"] = "LumpSum";
                }


                if (rdofixedlatepayment.Checked)
                {

                    UpdateAuditTrail("LatePaymentInterestRateOption", "Fixed", Item, Item.Fields.GetFieldByInternalName("LatePaymentInterestRateOption"));
                    Item["LatePaymentInterestRateOption"] = "Fixed";


                }

                if (rdovariablelatepayment.Checked)
                {
                    UpdateAuditTrail("LatePaymentInterestRateOption", "Prevaling", Item, Item.Fields.GetFieldByInternalName("LatePaymentInterestRateOption"));

                    Item["LatePaymentInterestRateOption"] = "Prevaling";

                }

                //end ph2 changes

                if (rdoAgreementOption1.Checked)
                {
                    UpdateAuditTrail("TypeOfAgreement", "Tenancy", Item, Item.Fields.GetFieldByInternalName("TypeOfAgreement"));
                    Item["TypeOfAgreement"] = "Tenancy";
                }

                if (rdoAgreementOption2.Checked)
                {
                    UpdateAuditTrail("TypeOfAgreement", "Licence", Item, Item.Fields.GetFieldByInternalName("TypeOfAgreement"));
                    Item["TypeOfAgreement"] = "Licence";
                }

                if (txtUtilitiesDeposit.Text != "")
                {
                    if (rAmount.IsMatch(txtUtilitiesDeposit.Text.Trim()))
                    {
                        UpdateAuditTrail("UtilitiesDepositAmount", txtUtilitiesDeposit.Text, Item, Item.Fields.GetFieldByInternalName("UtilitiesDepositAmount"));
                        Item["UtilitiesDepositAmount"] = Convert.ToDouble(txtUtilitiesDeposit.Text);
                    }
                    else
                    {
                        lblErrorMsg.Text = "Utilities Deposit Amount field should contain only numbers.";
                        return;
                    }
                }
                else
                {
                    Item["UtilitiesDepositAmount"] = "0.00";
                }

                if (txtRemarks.Text != "")
                {
                    UpdateAuditTrail("Remarks", txtRemarks.Text, Item, Item.Fields.GetFieldByInternalName("Remarks"));
                    Item["Remarks"] = txtRemarks.Text;
                }


                Item["AgreementTypeInt"] = "Tenancy Agreement";
                Item["FormName"] = FormType;
                Item["EditUrl"] = EditUrl;
                Item["ViewUrl"] = ViewUrl;

                if (drpAgreementStatus.SelectedItem.Text == "Draft")
                {
                    Item["AgreementStatus"] = "Submit for Approval";
                    //	drpAgreementStatus.Items.Add(new ListItem("Submit for Approval", "Pending for Approval"));
                }

                Item.Update();
                iRecord = Item.ID;
                iProcess = 1;
                //AddToLogFile("BtnSave == TenancyAgreementID == " + iRecord.ToString(), web.CurrentUser.LoginName);

                DateTime dtLEndDate = new DateTime();
                DeleteLeaseAgreementLicenseDraft(iRecord.ToString());
                AddLeaseAgreementLicenseDraft(iRecord.ToString(), ref dtLEndDate);

                #region Update Unit Info List

                if (iProcess == 1)
                {

                    //Update Unit Info List...
                    SPList UnitInfoList = web.Lists[strUnitInformationList];
                    foreach (int i in lbxUnitNumber.GetSelectedIndices())
                    {
                        int iSelectedID = Convert.ToInt16(lbxUnitNumber.Items[i].Value);
                        SPListItem UnitItem = UnitInfoList.GetItemById(iSelectedID);

                        switch (drpAgreementStatus.SelectedItem.Text)
                        {
                            case "Approved":
                                UnitItem["Status"] = "Tenanted";
                                UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                break;
                            case "Draft":
                                UnitItem["Status"] = "Committed";
                                UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                break;
                            case "Submit for Approval":
                                UnitItem["Status"] = "Committed";
                                UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                break;
                            case "Pending for Approval":
                                UnitItem["Status"] = "Committed";
                                UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                break;

                            case "ReSubmission":
                                UnitItem["Status"] = "Committed";
                                UnitItem["LastLicenseEndDate"] = dtLEndDate.Date;
                                break;

                            case "Rejected":
                                UnitItem["Status"] = "Available";
                                break;

                            default:
                                UnitItem["Status"] = "Available";
                                break;
                        }
                        UnitItem.Update();
                    }
                    //UnitInfoList.Update();
                }
                #endregion



                //#region Update License Details

                //if (iProcess == 1)
                //{

                //    //Save License details....
                //    SetRowData();
                //    DataTable table = ViewState["CurrentTable"] as DataTable;



                //    //ph2 

                //    SPList LicenseDetailList;

                //    //	if ((drpAgreementStatus.SelectedItem.Text != "Draft") && (mRecord == "Draft")) //ph2

                //    //	if (drpAgreementStatus.SelectedItem.Text != "Draft") //ph2


                //        LicenseDetailList = web.Lists[strTestTenantListDraft];




                //    //end ph2


                //    SPListItem LicenseItem = null;

                //    if (table.Rows.Count > 0)
                //    {
                //        foreach (DataRow row in table.Rows)
                //        {
                //            string ComplianceTitle1 = row.ItemArray[0].ToString();
                //            string ComplianceTitle2 = row.ItemArray[1].ToString();
                //            string ComplianceTitle3 = row.ItemArray[2].ToString();
                //            string ComplianceTitle4 = row.ItemArray[3].ToString();
                //            string ComplianceTitle5 = row.ItemArray[4].ToString();
                //            string ComplianceTitle6 = row.ItemArray[5].ToString();
                //            string ComplianceTitle7 = row.ItemArray[6].ToString();

                //            //AddToLogFile("BtnSave == ComplianceTitle 5 == " + ComplianceTitle5, web.CurrentUser.LoginName);

                //            if (ComplianceTitle1 != null || ComplianceTitle2 != null || ComplianceTitle3 != null || ComplianceTitle4 != null || ComplianceTitle5 != null)
                //            {
                //                //AddToLogFile("BtnSave == ComplianceTitle 1 == " + ComplianceTitle1, web.CurrentUser.LoginName);

                //                if ((ComplianceTitle5.Trim() == "0") || (!bEdit))
                //                {
                //                    //AddToLogFile("BtnSave == bEdit == " + bEdit.ToString(), web.CurrentUser.LoginName);
                //                    LicenseDetailList = web.Lists[strTestTenantListDraft];
                //                    LicenseItem = LicenseDetailList.Items.Add();
                //                }
                //                else if ((bEdit) && ComplianceTitle5.Trim() != "0")
                //                {

                //                    // disable ph2 	LicenseItem = LicenseDetailList.GetItemById(Convert.ToInt32(ComplianceTitle5));

                //                    //new code ph2  switching draft to pending for approval

                //                    if ((drpAgreementStatus.SelectedItem.Text == "Pending for Approval") && (mRecord == "Draft"))
                //                    {
                //                        LicenseDetailList = web.Lists[strTestTenantList];
                //                        LicenseItem = LicenseDetailList.Items.Add();
                //                    }
                //                    else
                //                    {
                //                        LicenseItem = LicenseDetailList.GetItemById(Convert.ToInt32(ComplianceTitle5));
                //                    }

                //                    //end ph2 

                //                }
                //                else
                //                {
                //                    lblErrorMsg.Text = "There is some issue in the License Details. Please contact System Administrator.";
                //                    AddToLogFile("BtnSave == License Item == " + ComplianceTitle5.ToString(), web.CurrentUser.LoginName);
                //                    return;
                //                }
                //                if (LicenseItem != null)
                //                {
                //                    LicenseItem["TenancyAgreementID"] = iRecord.ToString();

                //                    //AddToLogFile("BtnSave == ComplianceTitle 2 == " + ComplianceTitle2, web.CurrentUser.LoginName);

                //                    ComplianceTitle1 = ComplianceTitle1.Replace(" 12:00:00 AM", "");
                //                    ComplianceTitle2 = ComplianceTitle2.Replace(" 12:00:00 AM", "");
                //                    ComplianceTitle1 = ComplianceTitle1.Replace(" 00:00:00", "");
                //                    ComplianceTitle2 = ComplianceTitle2.Replace(" 00:00:00", "");

                //                    LicenseItem["LicenseStartDate"] = ComplianceTitle1;



                //                    LicenseItem["LicenseEndDate"] = ComplianceTitle2;



                //                    if (ComplianceTitle3.Trim() != "")
                //                    {
                //                        if (rAmount.IsMatch(ComplianceTitle3.Trim()))
                //                        {
                //                            UpdateAuditTrail("MonthlyRent", ComplianceTitle3, LicenseItem, LicenseItem.Fields.GetFieldByInternalName("MonthlyRent"));
                //                            LicenseItem["MonthlyRent"] = ComplianceTitle3;
                //                        }
                //                        else
                //                        {
                //                            lblErrorMsg.Text = "Monthly Rent field should contain only numbers.";
                //                            return;
                //                        }
                //                    }
                //                    else
                //                    {
                //                        LicenseItem["MonthlyRent"] = "0.00";
                //                    }

                //                    if (ComplianceTitle4.Trim() != "")
                //                    {
                //                        if (rAmount.IsMatch(ComplianceTitle4.Trim()))
                //                        {
                //                            UpdateAuditTrail("RentPSF", ComplianceTitle4, LicenseItem, LicenseItem.Fields.GetFieldByInternalName("RentPSF"));
                //                            LicenseItem["RentPSF"] = ComplianceTitle4;
                //                        }
                //                        else
                //                        {
                //                            lblErrorMsg.Text = "Monthly Rent field should contain only numbers.";
                //                            return;
                //                        }
                //                    }
                //                    else
                //                    {
                //                        LicenseItem["RentPSF"] = "0.00";
                //                    }

                //                    if (ComplianceTitle6.Trim() != "")
                //                    {
                //                        LicenseItem["NetFirstRent"] = ComplianceTitle6;

                //                    }

                //                    if (ComplianceTitle7.Trim() != "")
                //                    {
                //                        LicenseItem["NetLastRent"] = ComplianceTitle7;
                //                    }

                //                    LicenseItem["AgreementSQFT"] = lblSQFT.Text;

                //                    LicenseItem["CCName"] = iCCID.ToString();

                //                    LicenseItem.Update();
                //                }
                //            }
                //        }
                //        //LicenseDetailList.Update();
                //        Page.ClientScript.RegisterStartupScript(this.GetType(), "Message", "<script type='text/javascript'>alert('Submitted to Business Development Division for clearance');</script>");

                //    }
                //    else
                //    {
                //        AddToLogFile("btnSave_Click", "No License Details found");
                //        //no code...
                //    }

                //    iProcess = 0;

                //}
                //#endregion

                //if ((drpAgreementStatus.SelectedItem.Text == "Submit for Approval") && (mRecord == "Draft"))
                //    {
                //		deletedraft(); //ph2 to delete draft
                //	}

                Response.Redirect("..\\default.aspx");


            }
            catch (Exception ex)
            {
                AddToLogFile("Button Save In Tenancy Agreement Form:", "Error = " + ex.Message);
            }
        }


        //end ph2


        //ph2 check previous total tenure amount 


        public void checktenuretotalamtmessage()
        {

            lblrenewmessage.Text = "";

            SPWeb web = site.OpenWeb();

            SPList TAList;
            SPList TAList1;

            if (mRecord == "Draft")
            {
                //iRecord = Convert.ToInt32(Request.QueryString["drID"]);
                TAList = web.Lists[strAgreementListNameDraft];
            }
            else
            {
                //iRecord = Convert.ToInt32(Request.QueryString["rID"]);
                TAList = web.Lists[strAgreementListName];
            }

            //	SPListItem recordItem = TAList.GetItemById(iRecord);

            String PrevTRno = "";

            double prevamt = 0;
            double useramt = 0;

            useramt = Convert.ToDouble(lbltotaltenurevalue.Text);


            SPQuery qry1 = new SPQuery();

            qry1.Query = string.Format("<Where><Eq><FieldRef Name='TenancyRecordNumber' /><Value Type='Text'>" + lblRecordNumber.Text + "</Value></Eq></Where>");


            SPListItemCollection items1 = TAList.GetItems(qry1);


            foreach (SPListItem item in items1)
            {
                if (item["TenancyRecordNumberOld"].ToString() != null)
                {
                    PrevTRno = item["TenancyRecordNumberOld"].ToString();

                }
                else
                {

                    PrevTRno = "";

                }

            }
            PrevTANo.Text = PrevTRno;

            SPQuery qry = new SPQuery();

            qry.Query = string.Format("<Where><Eq><FieldRef Name='TenancyRecordNumber' /><Value Type='Text'>" + PrevTRno + "</Value></Eq></Where>");

            TAList1 = web.Lists[strAgreementListName];
            SPListItemCollection items = TAList1.GetItems(qry);

            // SPListItemCollection items = TAList.GetItems("Title", "TenancyRecordNumber", );

            //  SPListItem it = null;
            foreach (SPListItem item in items)
            {
                if (item["totaltenurevalue"].ToString() != null)

                {
                    prevamt = Convert.ToDouble(item["totaltenurevalue"].ToString());
                    Prevtenurevalue.Text = item["totaltenurevalue"].ToString();

                }
                else
                {
                    prevamt = 0;
                    Prevtenurevalue.Text = "0";

                }

            }



            if (useramt != prevamt)
            {
                // string msg = "Please take offline approval from Business Development team by fill in the form: [link to the form -> " + "<a href='http://sgehmoss01:23688'>http://sgehmoss01:23688</a>" + "]";
                string msg = "Please take offline approval from Business Development team";

                lblrenewmessage.Text = msg;
            }
            else
            {
                lblrenewmessage.Text = "";
            }

        }






        //ph2 calculate contract value based on months

        public void CalculateContractValue()
        {

            SetRowData();
            DataTable table = ViewState["CurrentTable"] as DataTable;

            // double tenurevalue = 0;

            int tenurevalue = 0;
            int tenuremonths = 0;

            if (table.Rows.Count > 0)
            {
                foreach (DataRow row in table.Rows)
                {
                    string ComplianceTitle1 = row.ItemArray[0].ToString();
                    string ComplianceTitle2 = row.ItemArray[1].ToString();
                    string ComplianceTitle3 = row.ItemArray[2].ToString();
                    string ComplianceTitle4 = row.ItemArray[3].ToString();
                    string ComplianceTitle5 = row.ItemArray[4].ToString();
                    string ComplianceTitle6 = row.ItemArray[5].ToString();
                    string ComplianceTitle7 = row.ItemArray[6].ToString();


                    if (ComplianceTitle3.Trim() != "")
                    {
                        DateTime startdate = Convert.ToDateTime(ComplianceTitle1);

                        DateTime enddate = Convert.ToDateTime(ComplianceTitle2);

                        //	TimeSpan ts = enddate - startdate;

                        TimeSpan ts = enddate.Subtract(startdate);

                        // Period period = Period.Between(startdate, enddate, PeriodUnits.Months);

                        int tenurevaluetemp = 0;
                        int tenuremonthstemp = 0;

                        //tenuremonthstemp = 
                        tenuremonthstemp = ((ts.Days + 1) / 30);

                        tenurevaluetemp = tenuremonthstemp * Convert.ToInt32(ComplianceTitle3.Trim());

                        tenuremonths += tenuremonthstemp;
                        tenurevalue += tenurevaluetemp;
                        lbltotaltenuremonths.Text = Convert.ToString(tenuremonths);
                        lbltotaltenurevalue.Text = Convert.ToString(tenurevalue);


                    }


                }


            }

        }


        //end ph2



        private void calculateTotalLease(double dMonthlyRent)
        {

            double dtenure = 0.00;
            double drenewal = 0.00;
            double dtotalstaggeredrent = 0.00;
            double totalesitmatedleasevalue = 0.00;


            if (txtTenureYear.Text != "")
            {
                dtenure = Convert.ToDouble(txtTenureYear.Text);
            }
            if (txtRenewalYear.Text != "")
            {
                drenewal = Convert.ToDouble(txtRenewalYear.Text);
            }
            dtotalstaggeredrent = dtenure + drenewal;

            // lblIQTLeaseValue.Text = "TEST $" + Math.Round(dtotalstaggeredrent * dMonthlyRent * 12, 2) + ". ";
            txtContractValue.Text = Convert.ToString(Math.Round(dtotalstaggeredrent * dMonthlyRent * 12, 2));
            // lblIQTLeaseValue.Text = Convert.ToString(dtotalstaggeredrent);

            if (txtContractValue.Text != "")
            {
                totalesitmatedleasevalue = Convert.ToDouble(txtContractValue.Text);
                updateTAapprovalauthority(totalesitmatedleasevalue); // UPDATE APPROVING AUTHORITY
            }

        }

        //end 


        // start approving authority

        private void updateTAapprovalauthority(double totalesitmatedleasevalue)
        {

            string total1 = "";

            total1 = Convert.ToString(totalesitmatedleasevalue);

            if ((total1 == "0.00") || (total1 == ""))
            {
                //matches[0].value = 0;
                lblApprovingAuthority.Text = "";
            }
            else
            {
                string dateString = Convert.ToString(dtApprovalDate.SelectedDate);

                if (dateString != "")
                {

                    DateTime ruleDateObject = new DateTime(2016, 06, 01);
                    //DateTime ruleDateObject = DateTime.Now.Date;
                    DateTime dateObject = Convert.ToDateTime(dateString).Date;

                    if (dateObject < ruleDateObject)

                    {
                        //alert('1');
                        if (totalesitmatedleasevalue > 0.00 && totalesitmatedleasevalue <= 100000.00)
                        {

                            lblApprovingAuthority.Text = "Constituency Tender Committee";
                        }

                        if (totalesitmatedleasevalue > 100000.00 && totalesitmatedleasevalue <= 1000000.00)
                        {
                            lblApprovingAuthority.Text = "Tender Board A";
                        }

                        if (totalesitmatedleasevalue > 1000000.00 && totalesitmatedleasevalue <= 10000000.00)
                        {
                            lblApprovingAuthority.Text = "Tender Board B";
                        }

                        if (totalesitmatedleasevalue > 10000000.00)
                        {
                            lblApprovingAuthority.Text = "Tender Board C";
                        }
                    }
                    else
                    {
                        if (totalesitmatedleasevalue > 0.00 && totalesitmatedleasevalue <= 250000.00)
                        {
                            lblApprovingAuthority.Text = "Constituency Tender Committee";

                        }

                        if (totalesitmatedleasevalue > 250000.00 && totalesitmatedleasevalue <= 1000000.00)
                        {
                            lblApprovingAuthority.Text = "Tender Board A";
                        }

                        if (totalesitmatedleasevalue > 1000000.00 && totalesitmatedleasevalue <= 10000000.00)
                        {
                            lblApprovingAuthority.Text = "Tender Board B";
                        }

                        if (totalesitmatedleasevalue > 10000000.00)
                        {
                            lblApprovingAuthority.Text = "Tender Board C";
                        }

                    }

                }
            }

        }

        //end approving authority

        public enum MessageScope
        {
            Success,
            Error
        }
    }

    public static class TMSCommon
    {
        public static object NoNull(object Data, object ReturnValue)
        {
            if (Data == DBNull.Value || Data == null)
                return ReturnValue;
            else
                return Data;
        }

        public static int BusinessDaysUntil(DateTime firstDay, DateTime lastDay, DataTable bankHolidays)
        {
            firstDay = firstDay.Date;
            lastDay = lastDay.Date;
            if (firstDay > lastDay)
                throw new ArgumentException("Incorrect last day " + lastDay);

            TimeSpan span = lastDay - firstDay;
            int businessDays = span.Days + 1;
            int fullWeekCount = businessDays / 7;
            // find out if there are weekends during the time exceedng the full weeks
            if (businessDays > fullWeekCount * 7)
            {
                // we are here to find out if there is a 1-day or 2-days weekend
                // in the time interval remaining after subtracting the complete weeks
                int firstDayOfWeek = (int)firstDay.DayOfWeek;
                int lastDayOfWeek = (int)lastDay.DayOfWeek;
                if (lastDayOfWeek < firstDayOfWeek)
                    lastDayOfWeek += 7;
                if (firstDayOfWeek <= 6)
                {
                    if (lastDayOfWeek >= 7)// Both Saturday and Sunday are in the remaining time interval
                        businessDays -= 2;
                    else if (lastDayOfWeek >= 6)// Only Saturday is in the remaining time interval
                        businessDays -= 1;
                }
                else if (firstDayOfWeek <= 7 && lastDayOfWeek >= 7)// Only Sunday is in the remaining time interval
                    businessDays -= 1;
            }

            // subtract the weekends during the full weeks in the interval
            businessDays -= fullWeekCount + fullWeekCount;

            // subtract the number of bank holidays during the time interval
            foreach (DataRow drbankHoliday in bankHolidays.Rows)
            {
                DateTime bh = Convert.ToDateTime(drbankHoliday["HolidayOn"].ToString());
                if (firstDay <= bh && bh <= lastDay)
                    --businessDays;
            }

            return businessDays;
        }
    }
}
