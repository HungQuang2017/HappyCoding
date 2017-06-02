$(document).ready(function() {
	if($('.my-breadcrumb').has("ul").length == 0)
	{
		$('.my-breadcrumb').css('display', 'none');
	} 
	/* content banner changed by page title */
	$('#bnrTitle').html('');
	if($('.bannerTitle').html())
	{				
		$('#bnrTitle').html($('.bannerTitle').html());
		$('#bnrDescription').html($('.bannerDescription').html());
	}
	else
	{
		$('#ContentBanner').css({ 'display': "none" });
	}
    /* for left menu multilevel */
    /* left navigation */
        $(".has-subitem:not(.current)").next(".submenu").find('li').hide();
        $('.navi-list a.current').closest('li:has(> a.has-subitem)').children('.submenu').show();
    
		$(document).on("click",".has-subitem",function(){
            $(".has-subitem:not(.current)").next(".submenu").find('li').slideUp();
             $(".has-subitem:not(.current)").find('i').removeClass('fa-caret-down');
            $(".has-subitem:not(.current)").find('i').addClass('fa-caret-right');
			$(this).next(".submenu").find('li').slideToggle(200);
            $(this).find('i').toggleClass("fa-caret-right fa-caret-down");
		}); 
    
    /* filters script*/
     $(".has-showmore").next(".showmore").hide();
		$(document).on("click",".has-showmore",function(){
			$(this).next(".showmore").slideToggle();
            $(this).find('i').toggleClass("fa-caret-down fa-caret-up");
		}); 
    
    
    $(document).on("click",".submenu > li > a",function(){
            $(".navi-list-multi-tabs > li").removeClass("active");
            $(".submenu > li > a").removeClass("active");
            $(this).addClass("active");
		}); 
    
    $(document).on("click",".navi-list-multi-tabs > li > a",function(){
            $(".submenu > li > a").removeClass("active");
		}); 
    
    $(".navi-list-multi-tabs li span").hide();
    $(".navi-list-multi-tabs li.active").children('.navi-current').show();
    
    $(document).on("click",function(){
			 $(".navi-list-multi-tabs li span").hide();
             $(".navi-list-multi-tabs li.active").children('.navi-current').show();
    }); 
    
    $(".submenu li span").hide();
    $(".submenu li a.active").next('.navi-current').show();
    
    $(document).on("click",function(){
			 $(".submenu li span").hide();
             $(".submenu li a.active").next('.navi-current').show();
    }); 
    /* end of it */
    
    
     $('.js-select').comboSelect();

    //for showing arrows on click
    $(".ml-left-single-menu li span").hide();
    $(".ml-left-single-menu li.active").children('.navi-current').show();
    
    $(document).on("click",function(){
			 $(".ml-left-single-menu li span").hide();
             $(".ml-left-single-menu li.active").children('.navi-current').show();
    }); 
     
    $('textarea[data-autoresize]').on('keyup input', function() {
        $(this).css('height', 'auto').css('height', this.scrollHeight + (this.offsetHeight - this.clientHeight));
    }).removeAttr('data-autoresize');

    $('body').on('click.dropdown', '.js-dropdown-toggle', function(e) {
        var $dropdown = $(this).parent().toggleClass('is-active');
        $('body').find('.ui-dropdown').not($dropdown).removeClass('is-active');
        e.preventDefault();
        e.stopPropagation();
    });
    $('html').on('click.closedropdown', function(e) {
        $('body').find('.ui-dropdown').removeClass('is-active');
    });
    $('html').on('keydown.closedropdown', function(e) {
        if (e.which == 27)
            $('body').find('.ui-dropdown').removeClass('is-active');
    });
    $('body').on('click.insideDropdown', '.ui-dropdown', function(e) {
        e.stopPropagation();
    });

    $('.input-control[required]').before("<span class='form-field-required'>*</span>");

    $('.input-control').blur(function() {
        var value = $(this).val() ? true : false;
        var required = $(this).prop("required");

        if ($(this).parents(".chosen-with-children").length > 0) {
            value = true;
            required = $(this).parents(".form-control-mds").find("select").prop("required");
        }

        if (value) {
            $(this).addClass('has-value');
            $(this).removeClass('invalid');
            $(this).parent().addClass("show-error");
            $(this).parents('.form-control-mds').find(".field-error").hide();
            $(this).parent().parent().removeClass("invalid");
        } else {
            $(this).removeClass('has-value');
            if (required) {
                $(this).addClass('invalid');
                if ($(this).parents(".date-picker")) {
                    $(this).parent().addClass("show-error");
                }
                if ($(this).parents(".search-field")) {
                    $(this).parent().parent().addClass("invalid");
                }

                $(this).parents('.form-control-mds').find(".field-error").show();
            }
        }
    });

    /* for date picker */

    $(".datepick").datepicker({
          autoclose: true,
        todayHighlight: true
      });
    
    $(".datepick").datepicker('update', new Date());
    
    $(".datepick1").datepicker({
          autoclose: true,
        todayHighlight: true
      });
    
    var dateNow = new Date();
    var weekBefore = new Date();
    weekBefore.setDate(dateNow.getDate()-7);    $(".datepick1").datepicker('update', weekBefore);
    
    $(".datepick2").datepicker({
          autoclose: true,
        todayHighlight: true
      });
    $(".datepick2").datepicker('update', dateNow);
    $(".today-value").text("15th December 2014");
    
    
    $(".cal-month-selector").datepicker({
        startView: 1,
        minViewMode: 1
    });
      
});