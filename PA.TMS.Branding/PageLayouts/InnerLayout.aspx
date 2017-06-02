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
.pa-topnavigation-fromroot{
    max-width: 100%;
}

table.ms-bottompaging a.ms-commandLink.ms-promlink-button.ms-promlink-button-enabled{
    -webkit-box-sizing: content-box;
    box-sizing: content-box;
}
</style>
	<div class="article article-body pa-innerlayout-container">
		<PublishingWebControls:EditModePanel runat="server" CssClass="edit-mode-panel title-edit">
			<SharePointWebControls:TextField runat="server" FieldName="Title"/>			
		</PublishingWebControls:EditModePanel>
		<div class="article-content"> 
			<section class="ml-content-one">
			    <div class="container">
			        <div class="row" style="margin-right: auto; margin-left:0">
			            <div class="col-md-9 correct-right-pad pa-apps-innerpage-top-left-zone">
			                <div>			                                     
			                	<WebPartPages:WebPartZone id="g_EE1ECEE66F7B48DB9336437E4CFF5806" runat="server" title="Top Zone Left"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>                    
			                </div>
			            </div>
			            <div class="col-md-3 pa-apps-innerpage-top-right-zone">
			                <div> 
			                	<WebPartPages:WebPartZone id="g_5B2F35B979574133B12638148B8BDE39" runat="server" title="Top Zone Right"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> 
			                </div>
			            </div>
			        </div>
			        <div class="row" style="margin-right: auto; margin-left:0;">
			            <div class="col-md-3 correct-right-pad pa-apps-innerpage-central-left-zone"> 
			            	<WebPartPages:WebPartZone id="g_E9CD57B5AA0B44C4867F8A83B1846B53" runat="server" title="Mid Zone Left"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone> 
			            </div>
			            <div class="col-md-9 pa-apps-innerpage-central-right-zone"> 
			            	<WebPartPages:WebPartZone id="g_B5904F97007A48DFBFDE220B38F43886" runat="server" title="Mid Zone Right"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>                
			            </div>
			        </div>			        
			    </div>
			</section>
            
			<section>
			    <div class="container pa-apps-innerpage-bottom-zone">	        
			    	<WebPartPages:WebPartZone id="g_C6414072164D4C98BEB19C65FCC93C68" runat="server" title="Content Editor Top Zone"><ZoneTemplate></ZoneTemplate></WebPartPages:WebPartZone>
			    </div>
			</section>
		</div>
		<PublishingWebControls:EditModePanel runat="server" CssClass="edit-mode-panel roll-up">
			<PublishingWebControls:RichImageField FieldName="PublishingRollupImage" AllowHyperLinks="false" runat="server" />
			<asp:Label text="<%$Resources:cms,Article_rollup_image_text15%>" CssClass="ms-textSmall" runat="server" />
		</PublishingWebControls:EditModePanel>
	</div>
</asp:Content>
