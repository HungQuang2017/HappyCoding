1. Add managed paths (apps)
2. Add DB before running the script to create new site --> make sure the collation is Latin1_General_CI_AS_KS_WS
3. Use the Sharegate tool to migrate: 

-	Workflow: No
-	Term store: No

-	Permission levels: All
-	Groups: All
-	Users: All

-   Reports:						(excepts data)
-	Visitors:						(excepts data)


-	Announcements:					(everything)
-	User Manual:					(everything)
-	Pass Details:					(everything)
-	Excel Templates:				(everything)




DVWP:
- Search: @Title then update the line :	
				<a href="/apps/gbms/Lists/GMRS/DispForm.aspx?ID={@ID}">
					<xsl:value-of disable-output-escaping="no" select="@Title" />
				</a>

4. Update permission of this folder: C:\Users\Administrator\AppData\Local\Temp (Everyone-fullcontrol)
5. Update permission level (Contribute):
	Check: Delete Items.
	UnCheck: Delete versions.
	Check: Use Remote Interfaces  -  Use SOAP, Web DAV, the Client Object Model or SharePoint Designer interfaces to access the Web site.
	Check: Use Client Integration Features  -  Use features which launch client applications. Without this permission, users will have to work on documents locally and upload their changes.
	Grant STPAdmin as sitecollection admin.
6. Update View Report webpart based on the permission of Reports library.