<%@ Page language="C#"   Inherits="Microsoft.SharePoint.Publishing.PublishingLayoutPage,Microsoft.SharePoint.Publishing,Version=16.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c" meta:progid="SharePoint.WebPartPage.Document" %>
<%@ Register Tagprefix="SharePointWebControls" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Register Tagprefix="WebPartPages" Namespace="Microsoft.SharePoint.WebPartPages" Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Register Tagprefix="PublishingWebControls" Namespace="Microsoft.SharePoint.Publishing.WebControls" Assembly="Microsoft.SharePoint.Publishing, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<%@ Register Tagprefix="PublishingNavigation" Namespace="Microsoft.SharePoint.Publishing.Navigation" Assembly="Microsoft.SharePoint.Publishing, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>
<asp:Content ContentPlaceholderID="PlaceHolderAdditionalPageHead" runat="server">
	<SharePointWebControls:CssRegistration name="<% $SPUrl:~sitecollection/Style Library/~language/Themable/Core Styles/pagelayouts15.css %>" runat="server"/>
	<PublishingWebControls:EditModePanel runat="server">
		<!-- Styles for edit mode only-->
		<SharePointWebControls:CssRegistration name="<% $SPUrl:~sitecollection/Style Library/~language/Themable/Core Styles/editmode15.css %>"
			After="<% $SPUrl:~sitecollection/Style Library/~language/Themable/Core Styles/pagelayouts15.css %>" runat="server"/>
	</PublishingWebControls:EditModePanel>
	<SharePointWebControls:FieldValue id="PageStylesField" FieldName="HeaderStyleDefinitions" runat="server"/>
</asp:Content>
<asp:Content ContentPlaceholderID="PlaceHolderPageTitle" runat="server">
	<SharePointWebControls:FieldValue id="PageTitle" FieldName="Title" runat="server"/>
</asp:Content>
<asp:Content ContentPlaceholderID="PlaceHolderPageTitleInTitleArea" runat="server">
	<WebPartPages:SPProxyWebPartManager runat="server" id="spproxywebpartmanager"></WebPartPages:SPProxyWebPartManager>	
	<SharePointWebControls:FieldValue FieldName="Title" runat="server"/>
</asp:Content>
<asp:Content ContentPlaceHolderId="PlaceHolderTitleBreadcrumb" runat="server"> 
	</asp:Content>
<asp:Content ContentPlaceholderID="PlaceHolderMain" runat="server">
<style type="text/css">
* {
	-webkit-box-sizing: border-box;
	-moz-box-sizing: border-box;
	box-sizing: border-box;
}
.ml-breadcrumbs
{
	display: none;
}
#sideNavBox
{
	display: none;
}
.ContentBanner
{
	display: none;
}
.pa-topnavigation-fromroot{
    max-width: 100%;
}
#pa-apps-pnlRightMenu{
    display: none;
}
table.ms-bottompaging a.ms-commandLink.ms-promlink-button.ms-promlink-button-enabled{
    -webkit-box-sizing: content-box;
    box-sizing: content-box;
}
.pa-apps-homepage-container .ms-headerSortTitleLink,
.pa-apps-homepage-container .pa-apps-homepage-top-left-zone .ms-noWrap{
    white-space: normal;
}
.pa-apps-homepage-top-left-zone td.ms-cellstyle.ms-vb2{
    word-break: break-all;
}
.pa-apps-homepage-container .ms-vb2 {
    padding: 4px 8px 4px 4px;
    font-size: 13px!important;
}
</style>
	<div class="article article-body pa-apps-homepage-container">
		<PublishingWebControls:EditModePanel runat="server" CssClass="edit-mode-panel title-edit">
			<SharePointWebControls:TextField runat="server" FieldName="Title"/>			
		</PublishingWebControls:EditModePanel>
		<div class="article-content"> 
			<section class="ml-content-one">
			    <div class="container">
			        <div class="row" style="margin-right: auto; margin-left:0">
			            <div class="col-md-8 correct-right-pad pa-apps-homepage-top-left-zone">
			                <div>			                                     
			                	<WebPartPages:WebPartZone id="g_E8560B5B2D2D4061B8194D1C870EDB60" runat="server" title="Top Zone Left"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>                    
			                </div>
			            </div>
			            <div class="col-md-4 pa-apps-homepage-top-right-zone">
			                <div> 
			                	<WebPartPages:WebPartZone id="g_A705C3202FA1402FB45EC2E591841911" runat="server" title="Top Zone Right"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> 
			                </div>
			            </div>
			        </div>
			        <div class="row" style="margin-right: auto; margin-left:0;">
			            <div class="col-md-4 correct-right-pad pa-apps-homepage-mid-left-zone"> 
			            	<WebPartPages:WebPartZone id="g_0360337370DE481AB91369B281EEDE3E" runat="server" title="Mid Zone Left"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> 
			            </div>
			            <div class="col-md-8 pa-apps-homepage-mid-right-zone"> 
			            	<WebPartPages:WebPartZone id="g_DF56FC29DF404250840ADE85CDA605EF" runat="server" title="Mid Zone Right"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>                
			            </div>
			        </div>			        
			    </div>
			</section>
            
			<section>
			    <div class="container">	        
			    	<WebPartPages:WebPartZone id="g_C6414072164D4C98BEB19C65FCC93C68" runat="server" title="Content Editor Top Zone"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>
			    </div>
			</section>
            <section>
			    <div class="container">
			        <div class="row" style="margin-right: auto; margin-left:0">
			            <div class="col-md-6 correct-right-pad pa-apps-homepage-ce-mid-left-zone">
			                <div>			                                     
			                	<WebPartPages:WebPartZone id="g_B89F4DA06C894BCD94A0068BD9E9E305" runat="server" title="Content Editor Middle Zone Left"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>                    
			                </div>
			            </div>
			            <div class="col-md-6 pa-apps-homepage-ce-mid-right-zone">
			                <div> 
			                	<WebPartPages:WebPartZone id="g_C0758DB067D247C5954DC7B346A83EE9" runat="server" title="Content Editor Middle Zone Right"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> 
			                </div>
			            </div>
			        </div>		        
			    </div>
			</section>
			<section class="billboard">
			    <div class="container">
			        <div class="row" style="margin-right: auto;">			            
				        <WebPartPages:WebPartZone id="g_D1A25B9549714FDAB4A056948A57BD55" runat="server" title="Content Editor Bottom"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>
			        </div>
			    </div>
			</section>
		</div>
		<PublishingWebControls:EditModePanel runat="server" CssClass="edit-mode-panel roll-up">
			<PublishingWebControls:RichImageField FieldName="PublishingRollupImage" AllowHyperLinks="false" runat="server" />
			<asp:Label text="<%$Resources:cms,Article_rollup_image_text15%>" CssClass="ms-textSmall" runat="server" />
		</PublishingWebControls:EditModePanel>
	</div>
</asp:Content>
