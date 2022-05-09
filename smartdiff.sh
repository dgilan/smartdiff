#!/bin/bash
HTML_TEMPLATE="\<\!DOCTYPEhtml\>\<htmllang=\"en\"\>\<head\>\<metacharset=\"UTF-8\"\>\<metahttp-equiv=\"X-UA-Compatible\"content=\"IE=edge\"\>\<metaname=\"viewport\"content=\"width=device-width\,initial-scale=1.0\"\>\<title\>SmartDiff\</title\>\<linkrel=\"stylesheet\"href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/styles/github.min.css\"/\>\<\!--diff2html-css--\>\<\!--diff2html-js-ui--\>\<script\>document.addEventListener\(\'DOMContentLoaded\'\,\(\)=\>\{consttargetElement=document.getElementById\(\'diff\'\)\;constdiff2htmlUi=newDiff2HtmlUI\(targetElement\)\;//diff2html-fileListToggle//diff2html-synchronisedScroll//diff2html-highlightCode\}\)\;\</script\>\<style\>header\{display:flex\;justify-content:center\;\}header.filter\{margin-left:10px\;font-weight:bold\;\}\</style\>\</head\>\<body\>\<headerid=\"title\"\>\<label\>Filteredby:\</label\>\<spanclass=\"filter\"\>\<\!--filterBy--\>\</span\>\</header\>\<divid=\"diff\"\>\<\!--diff2html-diff--\>\</div\>\</body\>\</html\>"
