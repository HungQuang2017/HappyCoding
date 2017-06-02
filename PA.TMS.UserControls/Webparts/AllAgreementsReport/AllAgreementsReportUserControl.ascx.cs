using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI.HtmlControls;
using Microsoft.SharePoint;
using System.Collections.Generic;
using Microsoft.SharePoint.Utilities;
using System.Text.RegularExpressions;

using System.IO;

namespace PA.TMS.UserControls.Webparts.AllAgreementsReport
{
    public partial class AllAgreementsReportUserControl : UserControl
    {
        #region "Global Variables"

        private bool bExport = false;
        string strCommunityClubListName = "CommunityClub";

        public SortDirection SrtDirection
        {
            get
            {
                if (ViewState["DirSort"] == null)
                {
                    ViewState["DirSort"] = SortDirection.Ascending;
                }
                return (SortDirection)ViewState["DirSort"];
            }
            set
            {
                ViewState["DirSort"] = value;
            }
        }


        #endregion

        /// <summary>
        /// Page load event
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                dtpFromDate.SelectedDate = DateTime.Now.Date;
                dtpToDate.SelectedDate = DateTime.Now.Date;
                GetAllCCNames();
                ddlType.Items.Add(new ListItem("Both", "0"));
                ddlType.Items.Add(new ListItem("Active", "1"));
                ddlType.Items.Add(new ListItem("Inactive", "2"));
            }
        }

        /// <summary>
        /// Get All CC Names
        /// </summary>
        public void GetAllCCNames()
        {
            ddlCCName.Items.Add(new ListItem("All", "All"));
            SPSite _site = SPContext.Current.Site;
            using (SPWeb web = _site.OpenWeb())
            {
                SPList CommunityClubList = web.Lists[strCommunityClubListName];

                foreach (SPListItem item in CommunityClubList.Items)
                {
                    ddlCCName.Items.Add(new ListItem(item["CCName"].ToString(), item["ID"].ToString()));
                }
            }
        }

        /// <summary>
        /// Get the Results gridview sorting (ASC or DESC)
        /// </summary>
        /// <param name="Column"></param>
        /// <returns></returns>
        private string GetSortDirection(string Column)
        {
            //By default the sort direction is Ascending
            string sortDirection = "ASC";
            //Retrieve the last column that was sorted
            string sortExpression = ViewState["SortExpression"] as string;
            if (sortExpression != null)
            {
                //Check if the same column being sorted
                //otherwise, the default value is returned
                if (sortExpression == Column)
                {
                    string lastDirection = ViewState["SortDirection"] as string;
                    if ((lastDirection != null) && (lastDirection == "ASC"))
                    {
                        sortDirection = "DESC";
                    }
                }
            }
            //Save new values in viewstate
            ViewState["SortDirection"] = sortDirection;
            ViewState["SortExpression"] = Column;
            return sortDirection;
        }

        /// <summary>
        /// Store the errors into text file in the local machine- to identify/verify if any errors there
        /// </summary>
        /// <param name="methodName"></param>
        /// <param name="Error"></param>
        public static void AddToLogFile(string methodName, string Error)
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
        }

        /// <summary>
        /// Grid view sorting
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void grdTMSTotalTenantedSpaces_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtResultsSrt = (DataTable)ViewState["ResultsTable"];
            if (dtResultsSrt != null)
            {
                DataView dtView = dtResultsSrt.DefaultView;
                dtView.Sort = e.SortExpression + " " + GetSortDirection(e.SortExpression);
                grdTMSTotalTenantedSpaces.DataSource = dtView.ToTable();
                grdTMSTotalTenantedSpaces.DataBind();
            }
            else
            {
                AddToLogFile("Sorting", "dtResultSrt is Null");
            }
        }

        /// <summary>
        /// Gridview Page index changing event 
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void grdTMSTotalTenantedSpaces_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            grdTMSTotalTenantedSpaces.PageIndex = e.NewPageIndex;
            GetSearchResults(false);
        }


        //This is for export report details to excel
        protected override void Render(HtmlTextWriter writer)
        {
            if (Page != null)
            {
                if (bExport)
                {
                    SPSecurity.RunWithElevatedPrivileges(delegate ()
                    {
                        SPSite _site = SPContext.Current.Site;
                        SPWeb _web = _site.OpenWeb();
                        SPList _list = _web.Lists["TenancyAgreement"];
                        SPList _LicenseList = _web.Lists["AgreementLicense"];
                        SPList UnitInfo = _web.Lists["UnitInformation"];
                        SPList CommunityClubList = _web.Lists[strCommunityClubListName];
                        string sReportFileName = "All Agreements";
                        SPQuery _qry = new SPQuery();
                        if (ddlCCName.SelectedItem.Text == "All")
                        {
                            _qry.Query = "<Where><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq></Where>";
                        }
                        else
                        {
                            _qry.Query = "<Where><And><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq><Eq><FieldRef Name='CCName' /><Value Type='Text'>" + ddlCCName.SelectedValue + "</Value></Eq></And></Where>";
                            sReportFileName = ddlCCName.SelectedValue + " Agreements";
                        }
                        SPListItemCollection _listItemcoll = _list.GetItems(_qry);
                        if (_listItemcoll.Count > 0)
                        {
                            grdExport.Visible = true;
                            DataTable dtUnique = _list.GetItems(_qry).GetDataTable();
                            //sunil...
                            DataColumn dCol1 = dtUnique.Columns.Add("FloorArea (sqm)", typeof(string));
                            dCol1.SetOrdinal(6);
                            dCol1.DefaultValue = string.Empty;
                            dtUnique.Columns["FloorArea"].ColumnName = "FloorArea (sq ft)";

                            DataColumn dCol2 = dtUnique.Columns.Add("Current Rent", typeof(double));
                            //dCol2.DefaultValue = 0.00;

                            foreach (DataRow drUniqueRow in dtUnique.Rows)
                            {
                                if (drUniqueRow["CCName"] != null)
                                {
                                    SPListItem oCItem = CommunityClubList.GetItemById(Convert.ToInt32(drUniqueRow["CCName"].ToString()));
                                    drUniqueRow["CCName"] = oCItem["CCName"].ToString();
                                    //dtCC["TermEndDate"] = dtCC["TermEndDate"].ToString().Replace("12:00:00 AM", "");
                                }

                                if (drUniqueRow["FloorArea (sq ft)"] != null)
                                {
                                    double dblSQFT = Convert.ToDouble(drUniqueRow["FloorArea (sq ft)"]);
                                    double dblSQMT = Math.Round(dblSQFT / 10.7639104, 2);
                                    drUniqueRow["FloorArea (sqm)"] = dblSQMT.ToString("N2");
                                }

                                drUniqueRow["ApprovalofAwardDate"] = drUniqueRow["ApprovalofAwardDate"].ToString().Replace("12:00:00 AM", "");

                                if (drUniqueRow["CCUnitNumber"] != null)
                                {
                                    string sUnits = drUniqueRow["CCUnitNumber"].ToString().Trim();
                                    sUnits = sUnits.TrimEnd(',');
                                    string sAllUnits = "";
                                    string[] values = sUnits.Split(',');
                                    for (int i = 0; i < values.Length; i++)
                                    {
                                        SPListItem oUItem = UnitInfo.GetItemById(Convert.ToInt32(values[i]));
                                        sAllUnits = sAllUnits + oUItem["Floor"].ToString() + " ,";
                                    }
                                    drUniqueRow["CCUnitNumber"] = sAllUnits.TrimEnd(',');
                                }


                                //Added on 08 Sep 2016 by sunil...To add current rent
                                SPQuery oAgreeLicQuery = new SPQuery();
                                oAgreeLicQuery.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID'/><Value Type='Text'>" + drUniqueRow["ID"].ToString() + "</Value></Eq></Where>";
                                SPListItemCollection oAgreeLic = _LicenseList.GetItems(oAgreeLicQuery);

                                if (oAgreeLic.Count > 0)
                                {

                                    DateTime dtfrm = new DateTime();
                                    DateTime dtTo = new DateTime();

                                    foreach (SPListItem oLicenceRow in oAgreeLic)
                                    {
                                        if (oLicenceRow["LicenseStartDate"] != null)
                                        {
                                            dtfrm = Convert.ToDateTime(oLicenceRow["LicenseStartDate"]);
                                        }

                                        if (oLicenceRow["LicenseEndDate"] != null)
                                        {
                                            dtTo = Convert.ToDateTime(oLicenceRow["LicenseEndDate"]);
                                        }

                                        if (dtpFromDate.SelectedDate >= dtfrm.Date && dtpFromDate.SelectedDate <= dtTo.Date)
                                        {
                                            drUniqueRow["Current Rent"] = Convert.ToDouble(oLicenceRow["MonthlyRent"]);

                                        }

                                    }
                                }

                            }


                            grdExport.DataSource = dtUnique;
                            grdExport.DataBind();

                            //grdTMSTotalTenantedSpaces.Visible = true;
                            this.bExport = false;
                            Page.Response.Clear();
                            Page.Response.Buffer = true;
                            Page.Response.ContentType = "application/ms-excel";
                            Page.Response.AddHeader("content-disposition", "attachment; filename=AllAgreements" + DateTime.Now + ".xls");
                            Page.Response.Charset = "UTF-8";
                            DateTime ct = DateTime.Now;
                            string currentdate = Convert.ToString(ct);
                            HttpContext.Current.Response.Write("<b><h1 style='Text-align:left; padding-left:65px; color: #008000; font-weight: bold; font-style: normal; font-size: large'>All Agreements</b></h1>");
                            this.EnableViewState = false;
                            System.IO.StringWriter sw = new System.IO.StringWriter();
                            System.Web.UI.HtmlTextWriter htw = new System.Web.UI.HtmlTextWriter(sw);
                            grdExport.RenderControl(htw);
                            Page.Response.Write(sw.ToString() + "<br/><br/><b>Report Date : " + currentdate + "</b><br/><b>Generated by : " + SPContext.Current.Web.CurrentUser.Name);
                            Page.Response.End();
                        }
                    });
                }
            }
            base.Render(writer);
        }

        /// <summary>
        /// Get all the Tenated spaces details 
        /// </summary>
        private void GetAllTenatedSpaces()
        {
            try
            {
                SPSecurity.RunWithElevatedPrivileges(delegate ()
                {
                    SPSite _site = SPContext.Current.Site;
                    using (SPWeb _web = _site.OpenWeb())
                    {
                        SPList _list = _web.Lists["TenancyAgreement"];
                        SPQuery _qry = new SPQuery();
                        _qry.Query = "<Where><IsNotNull><FieldRef Name='AgreementStatus' /></IsNotNull></Where>";
                        SPListItemCollection _listItemcoll = _list.GetItems(_qry);
                        if (_listItemcoll.Count > 0)
                        {
                            grdTMSTotalTenantedSpaces.DataSource = _listItemcoll.GetDataTable();
                            grdTMSTotalTenantedSpaces.DataBind();
                        }
                    }
                });
            }
            catch (Exception)
            {
                throw;
            }
        }

        /// <summary>
        /// Button click for Search the records
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void btnSearch_Click(object sender, EventArgs e)
        {

            lblErrorMessage.Visible = false;
            GetSearchResults(false);

        }

        /// <summary>
        /// Getting Search results based on the Search Criteria 
        /// </summary>
        public void GetSearchResults(bool isCCFilter)
        {

            SPSecurity.RunWithElevatedPrivileges(delegate ()
            {

                lblMessage.Text = string.Empty;
                SPSite _site = SPContext.Current.Site;
                SPWeb _web = _site.OpenWeb();
                SPList _list = _web.Lists["TenancyAgreement"];
                SPList CommunityClubList = _web.Lists[strCommunityClubListName];
                SPList UnitInfo = _web.Lists["UnitInformation"];
                SPList AgreementLic = _web.Lists["AgreementLicense"];

                SPQuery _qry = new SPQuery();
                if (isCCFilter)
                {
                    if (ddlCCName.SelectedItem.Text == "All")
                    {
                        _qry.Query = "<Where><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq></Where>";
                    }
                    else
                    {
                        _qry.Query = "<Where><And><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq><Eq><FieldRef Name='CCName' /><Value Type='Text'>" + ddlCCName.SelectedValue + "</Value></Eq></And></Where>";
                    }
                }
                else
                {
                    //_qry.Query = "<Where><And><Geq><FieldRef Name='Created' /><Value IncludeTimeValue='FALSE' Type='DateTime'>" + SPUtility.CreateISO8601DateTimeFromSystemDateTime(dtpFromDate.SelectedDate) + "</Value></Geq><And><Leq><FieldRef Name='Created' /><Value IncludeTimeValue='FALSE' Type='DateTime'>" + SPUtility.CreateISO8601DateTimeFromSystemDateTime(dtpToDate.SelectedDate) + "</Value></Leq><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq></And></And></Where>";
                    _qry.Query = "<Where><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq></Where>";
                }
                SPListItemCollection _listItemcoll = _list.GetItems(_qry);
                DataTable dtNew = CreateDataTable();
                if (_listItemcoll.Count > 0)
                {
                    //ddlCCName.Visible = true;
                    //lblCCName.Visible = true;
                    btnExportToExcel.Visible = true;
                    lblMessage.Visible = false;
                    grdTMSTotalTenantedSpaces.Visible = true;
                    DataRow dtrow = null;
                    DataTable dtUnique = _list.GetItems(_qry).GetDataTable();


                    //get data from Agreement License...
                    SPList _LicenceList = _web.Lists["AgreementLicense"];
                    SPQuery _LQry = new SPQuery();
                    lblMessage.Visible = true;

                    SPListItemCollection _LicenseItems = _LicenceList.Items;
                    if (_LicenseItems.Count > 0)
                    {
                        DataTable dtLicenseData = _LicenceList.Items.GetDataTable();
                        DataTable dtCloned = dtLicenseData.Clone();

                        dtCloned.Columns["LicenseEndDate"].DataType = typeof(DateTime);
                        foreach (DataRow row in dtLicenseData.Rows)
                        {
                            dtCloned.ImportRow(row);
                        }
                        //lblMessage.Text = dtCloned.Columns["LicenseEndDate"].DataType.ToString();

                        //DataRow[] drs = null;
                        string sCondition = string.Empty;

                        if (ddlType.SelectedValue == "0")
                        {
                            //do nothing..
                        }
                        else if (ddlType.SelectedValue == "1")
                        {
                            sCondition = "LicenseEndDate >= #" + DateTime.Today.ToString("MM/d/yyyy") + "#";
                        }
                        else if (ddlType.SelectedValue == "2")
                        {
                            sCondition = "LicenseEndDate <= #" + DateTime.Today.ToString("MM/d/yyyy") + "#";
                        }

                        DataView dvNew = new DataView(dtCloned, sCondition, "LicenseEndDate Asc", DataViewRowState.CurrentRows);
                        DataTable dtFiltered = dvNew.ToTable(true);

                        //drs = dtCloned.Select(sCondition, "LicenseEndDate desc");

                        if (dtFiltered.Rows.Count > 0)
                        {
                            //lblMessage.Text = "here 59 >>" + dtFiltered.Rows.Count.ToString() + " => " + dtFiltered.Rows[0]["TenancyAgreementID"] + " ==> ID is ==== " + dtFiltered.Rows[0]["ID"];
                            //lblMessage.Text = "here 59 >>" + dtFiltered.Rows.Count.ToString();
                        }

                        DataColumn dc1 = dtFiltered.Columns[2];
                        DataColumn dc2 = dtUnique.Columns.Add("TermEndDate", typeof(string));
                        dc2.DefaultValue = string.Empty;

                        //lblMessage.Text = " main list => " + dtUnique.Rows.Count.ToString() + " #### " + dtFiltered.Rows.Count.ToString();

                        foreach (DataRow dtUniqRow in dtUnique.Rows)
                        {

                            //lblMessage.Text = lblMessage.Text + " #### here 30 " + dtUnique.Rows[i]["ID"] + " >>> " + dtFiltered.Rows[i]["TenancyAgreementID"];

                            foreach (DataRow dtFilterRow in dtFiltered.Rows)
                            {
                                //lblMessage.Text = "here 398 " + dtFilterRow["LicenseEndDate"].ToString();
                                if (dtUniqRow["ID"].ToString() == dtFilterRow["TenancyAgreementID"].ToString())
                                {
                                    //lblMessage.Text = "here 399 " + dtFilterRow["LicenseEndDate"].ToString();
                                    //								if (dtFiltered.Rows[i]["LicenseEndDate"].ToString() != "")
                                    //								{
                                    //									lblMessage.Text = "here 290";
                                    dtUniqRow["TermEndDate"] = dtFilterRow["LicenseEndDate"].ToString();
                                    //								}
                                }
                            }
                        }
                    }
                    //lblMessage.Text = dtUnique.Rows.Count.ToString() + " >> " + dtUnique.Rows[0]["TermEndDate"].ToString();

                    DataTable dtFinalFilter = new DataView(dtUnique, "TermEndDate <> ''", "TermEndDate Desc", DataViewRowState.CurrentRows).ToTable();

                    //lblMessage.Text = "here 4098 " + dtFinalFilter.Rows.Count.ToString();

                    foreach (DataRow dtCC in dtFinalFilter.Rows)
                    {

                        //    double[] TotalRental = GetTotalRentalValue(_web, Convert.ToString(dtCC["CCName"]));

                        //    //if (TotalRental[0] > 0)
                        //    //{
                        //    dtrow = dtNew.NewRow();
                        //    dtrow["CCName"] = dtCC["CCName"].ToString();
                        if (dtCC["CCName"] != null)
                        {
                            SPListItem oCItem = CommunityClubList.GetItemById(Convert.ToInt32(dtCC["CCName"].ToString()));
                            dtCC["CCName"] = oCItem["CCName"].ToString();
                            dtCC["TermEndDate"] = dtCC["TermEndDate"].ToString().Replace("12:00:00 AM", "");
                        }
                        //    //dtrow["AgreementDate"] = GetTenants(_web, Convert.ToString(dtCC["CCName"]));		// Tenants;
                        //    dtNew.Rows.Add(dtrow);
                        //    //}

                        if (dtCC["CCUnitNumber"] != null)
                        {
                            string sUnits = dtCC["CCUnitNumber"].ToString().Trim();
                            sUnits = sUnits.TrimEnd(',');
                            string sAllUnits = "";
                            string[] values = sUnits.Split(',');
                            for (int i = 0; i < values.Length; i++)
                            {
                                SPListItem oUItem = UnitInfo.GetItemById(Convert.ToInt32(values[i]));
                                sAllUnits = sAllUnits + oUItem["Floor"].ToString() + " ,";
                            }
                            dtCC["CCUnitNumber"] = sAllUnits.TrimEnd(',');
                        }
                        dtCC["TenancyRecordNumber"] = dtCC["TenancyRecordNumber"] != null ? dtCC["TenancyRecordNumber"].ToString() : string.Empty;
                        dtCC["TradeCategory"] = dtCC["TradeCategory"] != null ? dtCC["TradeCategory"].ToString() : string.Empty;
                        dtCC["TenantName"] = dtCC["TenantName"] != null ? dtCC["TenantName"].ToString() : string.Empty;
                        dtCC["FloorArea"] = dtCC["FloorArea"] != null ? dtCC["FloorArea"].ToString() : string.Empty;
                        dtCC["RentalDueDate"] = dtCC["RentalDueDate"] != null ? dtCC["RentalDueDate"].ToString() : string.Empty;
                        SPQuery oAgreeLicQuery = new SPQuery();
                        oAgreeLicQuery.Query = "<Where><Eq><FieldRef Name='TenancyAgreementID'/><Value Type='Text'>" + dtCC["ID"].ToString() + "</Value></Eq></Where>";
                        SPListItemCollection oAgreeLic = AgreementLic.GetItems(oAgreeLicQuery);

                        string sLicDetails = "<p>No License Details availabe.</p>";

                        if (oAgreeLic.Count > 0)
                        {
                            sLicDetails = "<table border='1'><tr><th>Start Date</th><th>End Date</th><th>Monthly Rent</th></tr>";


                            foreach (SPListItem oAgreeLicItem in oAgreeLic)
                            {
                                sLicDetails = sLicDetails + "<tr>";
                                sLicDetails = sLicDetails + "<td>" + oAgreeLicItem["LicenseStartDate"].ToString() + "</td>";
                                sLicDetails = sLicDetails + "<td>" + oAgreeLicItem["LicenseEndDate"].ToString() + "</td>";
                                sLicDetails = sLicDetails + "<td>" + oAgreeLicItem["MonthlyRent"].ToString() + "</td>";
                                sLicDetails = sLicDetails + "</tr>";
                            }

                            sLicDetails = sLicDetails + "</table>";
                        }
                        dtCC["AgreementStatus"] = sLicDetails;

                    }


                    if (dtFinalFilter != null && dtFinalFilter.Rows.Count > 0)
                    {
                        grdTMSTotalTenantedSpaces.DataSource = dtFinalFilter;
                        grdTMSTotalTenantedSpaces.DataBind();
                        ViewState["ResultsTable"] = dtFinalFilter;
                        lblNoOfRecords.Visible = true;
                        lblNoOfRecords.Text = "Total No Of Records : " + dtFinalFilter.Rows.Count;
                    }
                    else
                    {
                        btnExportToExcel.Visible = false;
                        //ddlCCName.Visible = false;
                        //lblCCName.Visible = false;
                        lblMessage.Visible = true;
                        lblNoOfRecords.Visible = false;
                        grdTMSTotalTenantedSpaces.Visible = false;
                        lblMessage.Text = "No Records Found";
                    }
                }
                else
                {
                    btnExportToExcel.Visible = false;
                    //ddlCCName.Visible = false;
                    //lblCCName.Visible = false;
                    lblMessage.Visible = true;
                    lblNoOfRecords.Visible = false;
                    grdTMSTotalTenantedSpaces.Visible = false;
                    lblMessage.Text = "No Records Found";

                }

            });
        }


        /// <summary>
        /// Getting the total tenated spaces
        /// </summary>
        /// <param name="web"></param>
        /// <param name="CCName"></param>
        /// <returns></returns>
        public int GetTotalTenantedSpaces(SPWeb web, string CCName)
        {
            int totalValue = 0;
            int dTenantsCount = 0;
            SPList _units = web.Lists["TenancyAgreement"];
            SPQuery _oqry = new SPQuery();
            _oqry.Query = "<Where><And><Eq><FieldRef Name='CCName' /><Value Type='Text'>" + CCName + "</Value></Eq><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq></And></Where>";
            SPListItemCollection _tenAgrItemColl = _units.GetItems(_oqry);
            if (_tenAgrItemColl.Count > 0)
            {
                foreach (SPListItem newItem in _tenAgrItemColl)
                {
                    totalValue = Convert.ToInt32(totalValue) + Convert.ToInt32(newItem["FloorArea"]);
                }
                dTenantsCount = _tenAgrItemColl.Count;
            }

            return totalValue;
        }

        /// <summary>
        /// Getting the total tenanted value
        /// </summary>
        /// <param name="web"></param>
        /// <param name="CCName"></param>
        /// <param name="aggrementID"></param>
        /// <returns></returns>
        public double[] GetTotalRentalValue(SPWeb web, string CCName)
        {
            double[] dTotalDetails = { 0.00, 0.00 };
            SPList _units = web.Lists["AgreementLicense"];
            SPQuery _oqry = new SPQuery();
            _oqry.Query = "<Where><Eq><FieldRef Name='CCName' /><Value Type='Text'>" + CCName + "</Value></Eq></Where>";

            SPListItemCollection _unitItemColl = _units.GetItems(_oqry);
            if (_unitItemColl.Count > 0)
            {
                DateTime dtfrm = new DateTime();
                DateTime dtTo = new DateTime();

                foreach (SPListItem newItem in _unitItemColl)
                {
                    if (newItem["LicenseStartDate"] != null)
                    {
                        dtfrm = Convert.ToDateTime(newItem["LicenseStartDate"]);
                    }

                    if (newItem["LicenseEndDate"] != null)
                    {
                        dtTo = Convert.ToDateTime(newItem["LicenseEndDate"]);
                    }

                    if (dtfrm.Date >= dtpFromDate.SelectedDate && dtTo.Date <= dtpToDate.SelectedDate)
                    {
                        //lblErrorMessage.Text = lblErrorMessage.Text + " ==> " + dTotalDetails[0].ToString() + " == " + dTotalDetails[1].ToString();
                        dTotalDetails[0] = dTotalDetails[0] + Convert.ToDouble(newItem["MonthlyRent"]);
                        dTotalDetails[1] = dTotalDetails[1] + Convert.ToDouble(newItem["AgreementSQFT"]);
                    }
                }
            }

            return dTotalDetails;
        }

        /// <summary>
        /// New Data Table Creation based on custom columns
        /// </summary>
        /// <returns></returns>
        public DataTable CreateDataTable()
        {
            DataTable dtNewResults = new DataTable();
            dtNewResults.Columns.Add("ID", typeof(int));
            dtNewResults.Columns.Add("CCName", typeof(string));
            dtNewResults.Columns.Add("AgreementDate", typeof(string));
            dtNewResults.Columns.Add("TotalTenantedSpace", typeof(double));
            dtNewResults.Columns.Add("TotalRentalValue", typeof(double));
            dtNewResults.Columns.Add("AvgSqFt", typeof(double));
            return dtNewResults;
        }

        /// <summary>
        /// Export the Report gridview to excel
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void btnExportToExcel_Click(object sender, EventArgs e)
        {
            this.bExport = true;
        }
        protected void ddlCCName_SelectedIndexChanged(object sender, EventArgs e)
        {
            GetSearchResults(true);
        }

        protected void ddlType_SelectedIndexChanged(object sender, EventArgs e)
        {
            GetSearchResults(true);
        }


        /// <summary>
        /// Getting the number of tenants for a CC 
        /// </summary>
        /// <param name="web"></param>
        /// <param name="CCName"></param>
        /// <returns></returns>
        public int GetTenants(SPWeb web, string CCName)
        {
            int dTenantsCount = 0;
            SPList _units = web.Lists["TenancyAgreement"];
            SPQuery _oqry = new SPQuery();
            _oqry.Query = "<Where><And><Eq><FieldRef Name='CCName' /><Value Type='Text'>" + CCName + "</Value></Eq><Eq><FieldRef Name='AgreementStatus' /><Value Type='Text'>Approved</Value></Eq></And></Where>";
            SPListItemCollection _tenAgrItemColl = _units.GetItems(_oqry);
            if (_tenAgrItemColl.Count > 0)
            {
                dTenantsCount = _tenAgrItemColl.Count;
            }

            return dTenantsCount;
        }
    }
}
