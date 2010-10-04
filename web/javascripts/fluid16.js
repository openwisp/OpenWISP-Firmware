var fluid = {
Toggle : function(){
	var default_hide = {"help": true, "search": true };
	$.each(
		["connectivity-form", "server-form", "test"],
		function() {
			var el = $("#" + (this == 'accordon' ? 'accordion-block' : this) );
			if (default_hide[this]) {
				el.hide();
				$("[id='toggle-"+this+"']").addClass("hidden")
			}
			$("[id='toggle-"+this+"']")
			.bind("click", function(e) {
				if ($(this).hasClass('hidden')){
					$(this).removeClass('hidden').addClass('visible');
					el.slideDown();
				} else {
					$(this).removeClass('visible').addClass('hidden');
					el.slideUp();
				}
				e.preventDefault();
			});
		}
	);
},
Kwicks : function(){
	var animating = false;
    $("#kwick .kwick")
        .bind("mouseenter", function(e) {
            if (animating) return false;
            animating == true;
            $("#kwick .kwick").not(this).animate({ "width": 125 }, 200);
            $(this).animate({ "width": 485 }, 200, function() {
                animating = false;
            });
        });
    $("#kwick").bind("mouseleave", function(e) {
        $(".kwick", this).animate({ "width": 215 }, 200);
    });
},
SectionMenu : function(){
	$("#section-menu")
        .accordion({
            "header": "a.menuitem"
        })
        .bind("accordionchangestart", function(e, data) {
            data.newHeader.next().andSelf().addClass("current");
            data.oldHeader.next().andSelf().removeClass("current");
        })
        .find("a.menuitem:first").addClass("current")
        .next().addClass("current");
},
Accordion: function(){
	$("#accordion").accordion({
        'header': "h3.atStart"
    }).bind("accordionchangestart", function(e, data) {
        data.newHeader.css({
            "font-weight": "bold",
            "background": "#fff"
        });

        data.oldHeader.css({
            "font-weight": "normal",
            "background": "#eee"
        });
    }).find("h3.atStart:first").css({
        "font-weight": "bold",
        "background": "#fff"
    });
}
}
jQuery(function ($) {
	if($("#accordion").length){fluid.Accordion();}
	if($("[id$='ajax']").length){fluid.Ajax();}
	if($("[id^='toggle']").length){fluid.Toggle();}
	if($("#kwick .kwick").length){fluid.Kwicks();}
	if($("#section-menu").length){fluid.SectionMenu();}
});