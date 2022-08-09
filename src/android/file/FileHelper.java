package org.apache.cordova.inappbrowser.file;

import android.annotation.TargetApi;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.text.TextUtils;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.HashMap;

/**
 * @see https://gist.github.com/r0b0t3d/492f375ec6267a033c23b4ab8ab11e6a
 */
public class FileHelper {
    /**
     * @see https://www.freeformatter.com/mime-types-list.html
     */
    public static HashMap<String, String> getMimeTypeExtensionMapping() {
        HashMap<String, String> mapping = new HashMap<String, String>();

        mapping.put("application/vnd.hzn-3d-crossword", ".x3d");
        mapping.put("video/3gpp", ".3gp");
        mapping.put("video/3gpp2", ".3g2");
        mapping.put("application/vnd.mseq", ".mseq");
        mapping.put("application/vnd.3m.post-it-notes", ".pwn");
        mapping.put("application/vnd.3gpp.pic-bw-large", ".plb");
        mapping.put("application/vnd.3gpp.pic-bw-small", ".psb");
        mapping.put("application/vnd.3gpp.pic-bw-var", ".pvb");
        mapping.put("application/vnd.3gpp2.tcap", ".tcap");
        mapping.put("application/x-7z-compressed", ".7z");
        mapping.put("application/x-abiword", ".abw");
        mapping.put("application/x-ace-compressed", ".ace");
        mapping.put("application/vnd.americandynamics.acc", ".acc");
        mapping.put("application/vnd.acucobol", ".acu");
        mapping.put("application/vnd.acucorp", ".atc");
        mapping.put("audio/adpcm", ".adp");
        mapping.put("application/x-authorware-bin", ".aab");
        mapping.put("application/x-authorware-map", ".aam");
        mapping.put("application/x-authorware-seg", ".aas");
        mapping.put("application/vnd.adobe.air-application-installer-package+zip", ".air");
        mapping.put("application/x-shockwave-flash", ".swf");
        mapping.put("application/vnd.adobe.fxp", ".fxp");
        mapping.put("application/pdf", ".pdf");
        mapping.put("application/vnd.cups-ppd", ".ppd");
        mapping.put("application/x-director", ".dir");
        mapping.put("application/vnd.adobe.xdp+xml", ".xdp");
        mapping.put("application/vnd.adobe.xfdf", ".xfdf");
        mapping.put("audio/x-aac", ".aac");
        mapping.put("application/vnd.ahead.space", ".ahead");
        mapping.put("application/vnd.airzip.filesecure.azf", ".azf");
        mapping.put("application/vnd.airzip.filesecure.azs", ".azs");
        mapping.put("application/vnd.amazon.ebook", ".azw");
        mapping.put("application/vnd.amiga.ami", ".ami");
        mapping.put("application/andrew-inset", "N/A");
        mapping.put("application/vnd.android.package-archive", ".apk");
        mapping.put("application/vnd.anser-web-certificate-issue-initiation", ".cii");
        mapping.put("application/vnd.anser-web-funds-transfer-initiation", ".fti");
        mapping.put("application/vnd.antix.game-component", ".atx");
        mapping.put("application/x-apple-diskimage", ".dmg");
        mapping.put("application/vnd.apple.installer+xml", ".mpkg");
        mapping.put("application/applixware", ".aw");
        mapping.put("application/vnd.hhe.lesson-player", ".les");
        mapping.put("application/x-freearc", ".arc");
        mapping.put("application/vnd.aristanetworks.swi", ".swi");
        mapping.put("text/x-asm", ".s");
        mapping.put("application/atomcat+xml", ".atomcat");
        mapping.put("application/atomsvc+xml", ".atomsvc");
        mapping.put("application/atom+xml", ".atom");
        mapping.put("application/pkix-attr-cert", ".ac");
        mapping.put("audio/x-aiff", ".aif");
        mapping.put("video/x-msvideo", ".avi");
        mapping.put("application/vnd.audiograph", ".aep");
        mapping.put("image/vnd.dxf", ".dxf");
        mapping.put("model/vnd.dwf", ".dwf");
        mapping.put("image/avif", ".avif");
        mapping.put("text/plain-bas", ".par");
        mapping.put("application/x-bcpio", ".bcpio");
        mapping.put("application/octet-stream", ".bin");
        mapping.put("image/bmp", ".bmp");
        mapping.put("application/x-bittorrent", ".torrent");
        mapping.put("application/vnd.rim.cod", ".cod");
        mapping.put("application/vnd.blueice.multipass", ".mpm");
        mapping.put("application/vnd.bmi", ".bmi");
        mapping.put("application/x-sh", ".sh");
        mapping.put("image/prs.btif", ".btif");
        mapping.put("application/vnd.businessobjects", ".rep");
        mapping.put("application/x-bzip", ".bz");
        mapping.put("application/x-bzip2", ".bz2");
        mapping.put("application/x-csh", ".csh");
        mapping.put("text/x-c", ".c");
        mapping.put("application/vnd.chemdraw+xml", ".cdxml");
        mapping.put("text/css", ".css");
        mapping.put("application/x-cdf", ".cda");
        mapping.put("chemical/x-cdx", ".cdx");
        mapping.put("chemical/x-cml", ".cml");
        mapping.put("chemical/x-csml", ".csml");
        mapping.put("application/vnd.contact.cmsg", ".cdbcmsg");
        mapping.put("application/vnd.claymore", ".cla");
        mapping.put("application/vnd.clonk.c4group", ".c4g");
        mapping.put("image/vnd.dvb.subtitle", ".sub");
        mapping.put("application/cdmi-capability", ".cdmia");
        mapping.put("application/cdmi-container", ".cdmic");
        mapping.put("application/cdmi-domain", ".cdmid");
        mapping.put("application/cdmi-object", ".cdmio");
        mapping.put("application/cdmi-queue", ".cdmiq");
        mapping.put("application/vnd.cluetrust.cartomobile-config", ".c11amc");
        mapping.put("application/vnd.cluetrust.cartomobile-config-pkg", ".c11amz");
        mapping.put("image/x-cmu-raster", ".ras");
        mapping.put("model/vnd.collada+xml", ".dae");
        mapping.put("text/csv", ".csv");
        mapping.put("application/mac-compactpro", ".cpt");
        mapping.put("application/vnd.wap.wmlc", ".wmlc");
        mapping.put("image/cgm", ".cgm");
        mapping.put("x-conference/x-cooltalk", ".ice");
        mapping.put("image/x-cmx", ".cmx");
        mapping.put("application/vnd.xara", ".xar");
        mapping.put("application/vnd.cosmocaller", ".cmc");
        mapping.put("application/x-cpio", ".cpio");
        mapping.put("application/vnd.crick.clicker", ".clkx");
        mapping.put("application/vnd.crick.clicker.keyboard", ".clkk");
        mapping.put("application/vnd.crick.clicker.palette", ".clkp");
        mapping.put("application/vnd.crick.clicker.template", ".clkt");
        mapping.put("application/vnd.crick.clicker.wordbank", ".clkw");
        mapping.put("application/vnd.criticaltools.wbs+xml", ".wbs");
        mapping.put("application/vnd.rig.cryptonote", ".cryptonote");
        mapping.put("chemical/x-cif", ".cif");
        mapping.put("chemical/x-cmdf", ".cmdf");
        mapping.put("application/cu-seeme", ".cu");
        mapping.put("application/prs.cww", ".cww");
        mapping.put("text/vnd.curl", ".curl");
        mapping.put("text/vnd.curl.dcurl", ".dcurl");
        mapping.put("text/vnd.curl.mcurl", ".mcurl");
        mapping.put("text/vnd.curl.scurl", ".scurl");
        mapping.put("application/vnd.curl.car", ".car");
        mapping.put("application/vnd.curl.pcurl", ".pcurl");
        mapping.put("application/vnd.yellowriver-custom-menu", ".cmp");
        mapping.put("application/dssc+der", ".dssc");
        mapping.put("application/dssc+xml", ".xdssc");
        mapping.put("application/x-debian-package", ".deb");
        mapping.put("audio/vnd.dece.audio", ".uva");
        mapping.put("image/vnd.dece.graphic", ".uvi");
        mapping.put("video/vnd.dece.hd", ".uvh");
        mapping.put("video/vnd.dece.mobile", ".uvm");
        mapping.put("video/vnd.uvvu.mp4", ".uvu");
        mapping.put("video/vnd.dece.pd", ".uvp");
        mapping.put("video/vnd.dece.sd", ".uvs");
        mapping.put("video/vnd.dece.video", ".uvv");
        mapping.put("application/x-dvi", ".dvi");
        mapping.put("application/vnd.fdsn.seed", ".seed");
        mapping.put("application/x-dtbook+xml", ".dtb");
        mapping.put("application/x-dtbresource+xml", ".res");
        mapping.put("application/vnd.dvb.ait", ".ait");
        mapping.put("application/vnd.dvb.service", ".svc");
        mapping.put("audio/vnd.digital-winds", ".eol");
        mapping.put("image/vnd.djvu", ".djvu");
        mapping.put("application/xml-dtd", ".dtd");
        mapping.put("application/vnd.dolby.mlp", ".mlp");
        mapping.put("application/x-doom", ".wad");
        mapping.put("application/vnd.dpgraph", ".dpg");
        mapping.put("audio/vnd.dra", ".dra");
        mapping.put("application/vnd.dreamfactory", ".dfac");
        mapping.put("audio/vnd.dts", ".dts");
        mapping.put("audio/vnd.dts.hd", ".dtshd");
        mapping.put("image/vnd.dwg", ".dwg");
        mapping.put("application/vnd.dynageo", ".geo");
        mapping.put("application/ecmascript", ".es");
        mapping.put("application/vnd.ecowin.chart", ".mag");
        mapping.put("image/vnd.fujixerox.edmics-mmr", ".mmr");
        mapping.put("image/vnd.fujixerox.edmics-rlc", ".rlc");
        mapping.put("application/exi", ".exi");
        mapping.put("application/vnd.proteus.magazine", ".mgz");
        mapping.put("application/epub+zip", ".epub");
        mapping.put("message/rfc822", ".eml");
        mapping.put("application/vnd.enliven", ".nml");
        mapping.put("application/vnd.is-xpr", ".xpr");
        mapping.put("image/vnd.xiff", ".xif");
        mapping.put("application/vnd.xfdl", ".xfdl");
        mapping.put("application/emma+xml", ".emma");
        mapping.put("application/vnd.ezpix-album", ".ez2");
        mapping.put("application/vnd.ezpix-package", ".ez3");
        mapping.put("image/vnd.fst", ".fst");
        mapping.put("video/vnd.fvt", ".fvt");
        mapping.put("image/vnd.fastbidsheet", ".fbs");
        mapping.put("application/vnd.denovo.fcselayout-link", ".fe_launch");
        mapping.put("video/x-f4v", ".f4v");
        mapping.put("video/x-flv", ".flv");
        mapping.put("image/vnd.fpx", ".fpx");
        mapping.put("image/vnd.net-fpx", ".npx");
        mapping.put("text/vnd.fmi.flexstor", ".flx");
        mapping.put("video/x-fli", ".fli");
        mapping.put("application/vnd.fluxtime.clip", ".ftc");
        mapping.put("application/vnd.fdf", ".fdf");
        mapping.put("text/x-fortran", ".f");
        mapping.put("application/vnd.mif", ".mif");
        mapping.put("application/vnd.framemaker", ".fm");
        mapping.put("image/x-freehand", ".fh");
        mapping.put("application/vnd.fsc.weblaunch", ".fsc");
        mapping.put("application/vnd.frogans.fnc", ".fnc");
        mapping.put("application/vnd.frogans.ltf", ".ltf");
        mapping.put("application/vnd.fujixerox.ddd", ".ddd");
        mapping.put("application/vnd.fujixerox.docuworks", ".xdw");
        mapping.put("application/vnd.fujixerox.docuworks.binder", ".xbd");
        mapping.put("application/vnd.fujitsu.oasys", ".oas");
        mapping.put("application/vnd.fujitsu.oasys2", ".oa2");
        mapping.put("application/vnd.fujitsu.oasys3", ".oa3");
        mapping.put("application/vnd.fujitsu.oasysgp", ".fg5");
        mapping.put("application/vnd.fujitsu.oasysprs", ".bh2");
        mapping.put("application/x-futuresplash", ".spl");
        mapping.put("application/vnd.fuzzysheet", ".fzs");
        mapping.put("image/g3fax", ".g3");
        mapping.put("application/vnd.gmx", ".gmx");
        mapping.put("model/vnd.gtw", ".gtw");
        mapping.put("application/vnd.genomatix.tuxedo", ".txd");
        mapping.put("application/vnd.geogebra.file", ".ggb");
        mapping.put("application/vnd.geogebra.tool", ".ggt");
        mapping.put("model/vnd.gdl", ".gdl");
        mapping.put("application/vnd.geometry-explorer", ".gex");
        mapping.put("application/vnd.geonext", ".gxt");
        mapping.put("application/vnd.geoplan", ".g2w");
        mapping.put("application/vnd.geospace", ".g3w");
        mapping.put("application/x-font-ghostscript", ".gsf");
        mapping.put("application/x-font-bdf", ".bdf");
        mapping.put("application/x-gtar", ".gtar");
        mapping.put("application/x-texinfo", ".texinfo");
        mapping.put("application/x-gnumeric", ".gnumeric");
        mapping.put("application/vnd.google-earth.kml+xml", ".kml");
        mapping.put("application/vnd.google-earth.kmz", ".kmz");
        mapping.put("application/gpx+xml", ".gpx");
        mapping.put("application/vnd.grafeq", ".gqf");
        mapping.put("image/gif", ".gif");
        mapping.put("text/vnd.graphviz", ".gv");
        mapping.put("application/vnd.groove-account", ".gac");
        mapping.put("application/vnd.groove-help", ".ghf");
        mapping.put("application/vnd.groove-identity-message", ".gim");
        mapping.put("application/vnd.groove-injector", ".grv");
        mapping.put("application/vnd.groove-tool-message", ".gtm");
        mapping.put("application/vnd.groove-tool-template", ".tpl");
        mapping.put("application/vnd.groove-vcard", ".vcg");
        mapping.put("application/gzip", ".gz");
        mapping.put("video/h261", ".h261");
        mapping.put("video/h263", ".h263");
        mapping.put("video/h264", ".h264");
        mapping.put("application/vnd.hp-hpid", ".hpid");
        mapping.put("application/vnd.hp-hps", ".hps");
        mapping.put("application/x-hdf", ".hdf");
        mapping.put("audio/vnd.rip", ".rip");
        mapping.put("application/vnd.hbci", ".hbci");
        mapping.put("application/vnd.hp-jlyt", ".jlt");
        mapping.put("application/vnd.hp-pcl", ".pcl");
        mapping.put("application/vnd.hp-hpgl", ".hpgl");
        mapping.put("application/vnd.yamaha.hv-script", ".hvs");
        mapping.put("application/vnd.yamaha.hv-dic", ".hvd");
        mapping.put("application/vnd.yamaha.hv-voice", ".hvp");
        mapping.put("application/vnd.hydrostatix.sof-data", ".sfd-hdstx");
        mapping.put("application/hyperstudio", ".stk");
        mapping.put("application/vnd.hal+xml", ".hal");
        mapping.put("text/html", ".html");
        mapping.put("application/vnd.ibm.rights-management", ".irm");
        mapping.put("application/vnd.ibm.secure-container", ".sc");
        mapping.put("text/calendar", ".ics");
        mapping.put("application/vnd.iccprofile", ".icc");
        mapping.put("image/x-icon", ".ico");
        mapping.put("application/vnd.igloader", ".igl");
        mapping.put("image/ief", ".ief");
        mapping.put("application/vnd.immervision-ivp", ".ivp");
        mapping.put("application/vnd.immervision-ivu", ".ivu");
        mapping.put("application/reginfo+xml", ".rif");
        mapping.put("text/vnd.in3d.3dml", ".3dml");
        mapping.put("text/vnd.in3d.spot", ".spot");
        mapping.put("model/iges", ".igs");
        mapping.put("application/vnd.intergeo", ".i2g");
        mapping.put("application/vnd.cinderella", ".cdy");
        mapping.put("application/vnd.intercon.formnet", ".xpw");
        mapping.put("application/vnd.isac.fcs", ".fcs");
        mapping.put("application/ipfix", ".ipfix");
        mapping.put("application/pkix-cert", ".cer");
        mapping.put("application/pkixcmp", ".pki");
        mapping.put("application/pkix-crl", ".crl");
        mapping.put("application/pkix-pkipath", ".pkipath");
        mapping.put("application/vnd.insors.igm", ".igm");
        mapping.put("application/vnd.ipunplugged.rcprofile", ".rcprofile");
        mapping.put("application/vnd.irepository.package+xml", ".irp");
        mapping.put("text/vnd.sun.j2me.app-descriptor", ".jad");
        mapping.put("application/java-archive", ".jar");
        mapping.put("application/java-vm", ".class");
        mapping.put("application/x-java-jnlp-file", ".jnlp");
        mapping.put("application/java-serialized-object", ".ser");
        mapping.put("text/x-java-source,java", ".java");
        mapping.put("application/javascript", ".js");
        mapping.put("text/javascript", ".mjs");
        mapping.put("text/javascript", ".mjs");
        mapping.put("application/json", ".json");
        mapping.put("application/vnd.joost.joda-archive", ".joda");
        mapping.put("video/jpm", ".jpm");
        mapping.put("image/jpeg", ".jpeg");
        mapping.put("image/x-citrix-jpeg", ".jpeg");
        mapping.put("image/pjpeg", ".pjpeg");
        mapping.put("video/jpeg", ".jpgv");
        mapping.put("application/ld+json", ".jsonld");
        mapping.put("application/vnd.kahootz", ".ktz");
        mapping.put("application/vnd.chipnuts.karaoke-mmd", ".mmd");
        mapping.put("application/vnd.kde.karbon", ".karbon");
        mapping.put("application/vnd.kde.kchart", ".chrt");
        mapping.put("application/vnd.kde.kformula", ".kfo");
        mapping.put("application/vnd.kde.kivio", ".flw");
        mapping.put("application/vnd.kde.kontour", ".kon");
        mapping.put("application/vnd.kde.kpresenter", ".kpr");
        mapping.put("application/vnd.kde.kspread", ".ksp");
        mapping.put("application/vnd.kde.kword", ".kwd");
        mapping.put("application/vnd.kenameaapp", ".htke");
        mapping.put("application/vnd.kidspiration", ".kia");
        mapping.put("application/vnd.kinar", ".kne");
        mapping.put("application/vnd.kodak-descriptor", ".sse");
        mapping.put("application/vnd.las.las+xml", ".lasxml");
        mapping.put("application/x-latex", ".latex");
        mapping.put("application/vnd.llamagraphics.life-balance.desktop", ".lbd");
        mapping.put("application/vnd.llamagraphics.life-balance.exchange+xml", ".lbe");
        mapping.put("application/vnd.jam", ".jam");
        mapping.put("application/vnd.lotus-1-2-3", ".123");
        mapping.put("application/vnd.lotus-approach", ".apr");
        mapping.put("application/vnd.lotus-freelance", ".pre");
        mapping.put("application/vnd.lotus-notes", ".nsf");
        mapping.put("application/vnd.lotus-organizer", ".org");
        mapping.put("application/vnd.lotus-screencam", ".scm");
        mapping.put("application/vnd.lotus-wordpro", ".lwp");
        mapping.put("audio/vnd.lucent.voice", ".lvp");
        mapping.put("audio/x-mpegurl", ".m3u");
        mapping.put("video/x-m4v", ".m4v");
        mapping.put("application/mac-binhex40", ".hqx");
        mapping.put("application/vnd.macports.portpkg", ".portpkg");
        mapping.put("application/vnd.osgeo.mapguide.package", ".mgp");
        mapping.put("application/marc", ".mrc");
        mapping.put("application/marcxml+xml", ".mrcx");
        mapping.put("application/mxf", ".mxf");
        mapping.put("application/vnd.wolfram.player", ".nbp");
        mapping.put("application/mathematica", ".ma");
        mapping.put("application/mathml+xml", ".mathml");
        mapping.put("application/mbox", ".mbox");
        mapping.put("application/vnd.medcalcdata", ".mc1");
        mapping.put("application/mediaservercontrol+xml", ".mscml");
        mapping.put("application/vnd.mediastation.cdkey", ".cdkey");
        mapping.put("application/vnd.mfer", ".mwf");
        mapping.put("application/vnd.mfmp", ".mfm");
        mapping.put("model/mesh", ".msh");
        mapping.put("application/mads+xml", ".mads");
        mapping.put("application/mets+xml", ".mets");
        mapping.put("application/mods+xml", ".mods");
        mapping.put("application/metalink4+xml", ".meta4");
        mapping.put("application/vnd.mcd", ".mcd");
        mapping.put("application/vnd.micrografx.flo", ".flo");
        mapping.put("application/vnd.micrografx.igx", ".igx");
        mapping.put("application/vnd.eszigno3+xml", ".es3");
        mapping.put("application/x-msaccess", ".mdb");
        mapping.put("video/x-ms-asf", ".asf");
        mapping.put("application/x-msdownload", ".exe");
        mapping.put("application/vnd.ms-artgalry", ".cil");
        mapping.put("application/vnd.ms-cab-compressed", ".cab");
        mapping.put("application/vnd.ms-ims", ".ims");
        mapping.put("application/x-ms-application", ".application");
        mapping.put("application/x-msclip", ".clp");
        mapping.put("image/vnd.ms-modi", ".mdi");
        mapping.put("application/vnd.ms-fontobject", ".eot");
        mapping.put("application/vnd.ms-excel", ".xls");
        mapping.put("application/vnd.ms-excel.addin.macroenabled.12", ".xlam");
        mapping.put("application/vnd.ms-excel.sheet.binary.macroenabled.12", ".xlsb");
        mapping.put("application/vnd.ms-excel.template.macroenabled.12", ".xltm");
        mapping.put("application/vnd.ms-excel.sheet.macroenabled.12", ".xlsm");
        mapping.put("application/vnd.ms-htmlhelp", ".chm");
        mapping.put("application/x-mscardfile", ".crd");
        mapping.put("application/vnd.ms-lrm", ".lrm");
        mapping.put("application/x-msmediaview", ".mvb");
        mapping.put("application/x-msmoney", ".mny");
        mapping.put("application/vnd.openxmlformats-officedocument.presentationml.presentation", ".pptx");
        mapping.put("application/vnd.openxmlformats-officedocument.presentationml.slide", ".sldx");
        mapping.put("application/vnd.openxmlformats-officedocument.presentationml.slideshow", ".ppsx");
        mapping.put("application/vnd.openxmlformats-officedocument.presentationml.template", ".potx");
        mapping.put("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", ".xlsx");
        mapping.put("application/vnd.openxmlformats-officedocument.spreadsheetml.template", ".xltx");
        mapping.put("application/vnd.openxmlformats-officedocument.wordprocessingml.document", ".docx");
        mapping.put("application/vnd.openxmlformats-officedocument.wordprocessingml.template", ".dotx");
        mapping.put("application/x-msbinder", ".obd");
        mapping.put("application/vnd.ms-officetheme", ".thmx");
        mapping.put("application/onenote", ".onetoc");
        mapping.put("audio/vnd.ms-playready.media.pya", ".pya");
        mapping.put("video/vnd.ms-playready.media.pyv", ".pyv");
        mapping.put("application/vnd.ms-powerpoint", ".ppt");
        mapping.put("application/vnd.ms-powerpoint.addin.macroenabled.12", ".ppam");
        mapping.put("application/vnd.ms-powerpoint.slide.macroenabled.12", ".sldm");
        mapping.put("application/vnd.ms-powerpoint.presentation.macroenabled.12", ".pptm");
        mapping.put("application/vnd.ms-powerpoint.slideshow.macroenabled.12", ".ppsm");
        mapping.put("application/vnd.ms-powerpoint.template.macroenabled.12", ".potm");
        mapping.put("application/vnd.ms-project", ".mpp");
        mapping.put("application/x-mspublisher", ".pub");
        mapping.put("application/x-msschedule", ".scd");
        mapping.put("application/x-silverlight-app", ".xap");
        mapping.put("application/vnd.ms-pki.stl", ".stl");
        mapping.put("application/vnd.ms-pki.seccat", ".cat");
        mapping.put("application/vnd.visio", ".vsd");
        mapping.put("application/vnd.visio2013", ".vsdx");
        mapping.put("video/x-ms-wm", ".wm");
        mapping.put("audio/x-ms-wma", ".wma");
        mapping.put("audio/x-ms-wax", ".wax");
        mapping.put("video/x-ms-wmx", ".wmx");
        mapping.put("application/x-ms-wmd", ".wmd");
        mapping.put("application/vnd.ms-wpl", ".wpl");
        mapping.put("application/x-ms-wmz", ".wmz");
        mapping.put("video/x-ms-wmv", ".wmv");
        mapping.put("video/x-ms-wvx", ".wvx");
        mapping.put("application/x-msmetafile", ".wmf");
        mapping.put("application/x-msterminal", ".trm");
        mapping.put("application/msword", ".doc");
        mapping.put("application/vnd.ms-word.document.macroenabled.12", ".docm");
        mapping.put("application/vnd.ms-word.template.macroenabled.12", ".dotm");
        mapping.put("application/x-mswrite", ".wri");
        mapping.put("application/vnd.ms-works", ".wps");
        mapping.put("application/x-ms-xbap", ".xbap");
        mapping.put("application/vnd.ms-xpsdocument", ".xps");
        mapping.put("audio/midi", ".midi");
        mapping.put("audio/midi", ".mid");
        mapping.put("application/vnd.ibm.minipay", ".mpy");
        mapping.put("application/vnd.ibm.modcap", ".afp");
        mapping.put("application/vnd.jcp.javame.midlet-rms", ".rms");
        mapping.put("application/vnd.tmobile-livetv", ".tmo");
        mapping.put("application/x-mobipocket-ebook", ".prc");
        mapping.put("application/vnd.mobius.mbk", ".mbk");
        mapping.put("application/vnd.mobius.dis", ".dis");
        mapping.put("application/vnd.mobius.plc", ".plc");
        mapping.put("application/vnd.mobius.mqy", ".mqy");
        mapping.put("application/vnd.mobius.msl", ".msl");
        mapping.put("application/vnd.mobius.txf", ".txf");
        mapping.put("application/vnd.mobius.daf", ".daf");
        mapping.put("text/vnd.fly", ".fly");
        mapping.put("application/vnd.mophun.certificate", ".mpc");
        mapping.put("application/vnd.mophun.application", ".mpn");
        mapping.put("video/mj2", ".mj2");
        mapping.put("audio/mpeg", ".mpga");
        mapping.put("video/mp2t", ".ts");
        mapping.put("video/vnd.mpegurl", ".mxu");
        mapping.put("video/mpeg", ".mpeg");
        mapping.put("application/mp21", ".m21");
        mapping.put("audio/mp4", ".mp4a");
        mapping.put("video/mp4", ".mp4");
        mapping.put("application/mp4", ".mp4");
        mapping.put("application/vnd.apple.mpegurl", ".m3u8");
        mapping.put("application/vnd.musician", ".mus");
        mapping.put("application/vnd.muvee.style", ".msty");
        mapping.put("application/xv+xml", ".mxml");
        mapping.put("application/vnd.nokia.n-gage.data", ".ngdat");
        mapping.put("application/vnd.nokia.n-gage.symbian.install", ".n-gage");
        mapping.put("application/x-dtbncx+xml", ".ncx");
        mapping.put("application/x-netcdf", ".nc");
        mapping.put("application/vnd.neurolanguage.nlu", ".nlu");
        mapping.put("application/vnd.dna", ".dna");
        mapping.put("application/vnd.noblenet-directory", ".nnd");
        mapping.put("application/vnd.noblenet-sealer", ".nns");
        mapping.put("application/vnd.noblenet-web", ".nnw");
        mapping.put("application/vnd.nokia.radio-preset", ".rpst");
        mapping.put("application/vnd.nokia.radio-presets", ".rpss");
        mapping.put("text/n3", ".n3");
        mapping.put("application/vnd.novadigm.edm", ".edm");
        mapping.put("application/vnd.novadigm.edx", ".edx");
        mapping.put("application/vnd.novadigm.ext", ".ext");
        mapping.put("application/vnd.flographit", ".gph");
        mapping.put("audio/vnd.nuera.ecelp4800", ".ecelp4800");
        mapping.put("audio/vnd.nuera.ecelp7470", ".ecelp7470");
        mapping.put("audio/vnd.nuera.ecelp9600", ".ecelp9600");
        mapping.put("application/oda", ".oda");
        mapping.put("application/ogg", ".ogx");
        mapping.put("audio/ogg", ".oga");
        mapping.put("video/ogg", ".ogv");
        mapping.put("application/vnd.oma.dd2+xml", ".dd2");
        mapping.put("application/vnd.oasis.opendocument.text-web", ".oth");
        mapping.put("application/oebps-package+xml", ".opf");
        mapping.put("application/vnd.intu.qbo", ".qbo");
        mapping.put("application/vnd.openofficeorg.extension", ".oxt");
        mapping.put("application/vnd.yamaha.openscoreformat", ".osf");
        mapping.put("audio/webm", ".weba");
        mapping.put("video/webm", ".webm");
        mapping.put("application/vnd.oasis.opendocument.chart", ".odc");
        mapping.put("application/vnd.oasis.opendocument.chart-template", ".otc");
        mapping.put("application/vnd.oasis.opendocument.database", ".odb");
        mapping.put("application/vnd.oasis.opendocument.formula", ".odf");
        mapping.put("application/vnd.oasis.opendocument.formula-template", ".odft");
        mapping.put("application/vnd.oasis.opendocument.graphics", ".odg");
        mapping.put("application/vnd.oasis.opendocument.graphics-template", ".otg");
        mapping.put("application/vnd.oasis.opendocument.image", ".odi");
        mapping.put("application/vnd.oasis.opendocument.image-template", ".oti");
        mapping.put("application/vnd.oasis.opendocument.presentation", ".odp");
        mapping.put("application/vnd.oasis.opendocument.presentation-template", ".otp");
        mapping.put("application/vnd.oasis.opendocument.spreadsheet", ".ods");
        mapping.put("application/vnd.oasis.opendocument.spreadsheet-template", ".ots");
        mapping.put("application/vnd.oasis.opendocument.text", ".odt");
        mapping.put("application/vnd.oasis.opendocument.text-master", ".odm");
        mapping.put("application/vnd.oasis.opendocument.text-template", ".ott");
        mapping.put("image/ktx", ".ktx");
        mapping.put("application/vnd.sun.xml.calc", ".sxc");
        mapping.put("application/vnd.sun.xml.calc.template", ".stc");
        mapping.put("application/vnd.sun.xml.draw", ".sxd");
        mapping.put("application/vnd.sun.xml.draw.template", ".std");
        mapping.put("application/vnd.sun.xml.impress", ".sxi");
        mapping.put("application/vnd.sun.xml.impress.template", ".sti");
        mapping.put("application/vnd.sun.xml.math", ".sxm");
        mapping.put("application/vnd.sun.xml.writer", ".sxw");
        mapping.put("application/vnd.sun.xml.writer.global", ".sxg");
        mapping.put("application/vnd.sun.xml.writer.template", ".stw");
        mapping.put("application/x-font-otf", ".otf");
        mapping.put("audio/opus", ".opus");
        mapping.put("application/vnd.yamaha.openscoreformat.osfpvg+xml", ".osfpvg");
        mapping.put("application/vnd.osgi.dp", ".dp");
        mapping.put("application/vnd.palm", ".pdb");
        mapping.put("text/x-pascal", ".p");
        mapping.put("application/vnd.pawaafile", ".paw");
        mapping.put("application/vnd.hp-pclxl", ".pclxl");
        mapping.put("application/vnd.picsel", ".efif");
        mapping.put("image/x-pcx", ".pcx");
        mapping.put("image/vnd.adobe.photoshop", ".psd");
        mapping.put("application/pics-rules", ".prf");
        mapping.put("image/x-pict", ".pic");
        mapping.put("application/x-chat", ".chat");
        mapping.put("application/pkcs10", ".p10");
        mapping.put("application/x-pkcs12", ".p12");
        mapping.put("application/pkcs7-mime", ".p7m");
        mapping.put("application/pkcs7-signature", ".p7s");
        mapping.put("application/x-pkcs7-certreqresp", ".p7r");
        mapping.put("application/x-pkcs7-certificates", ".p7b");
        mapping.put("application/pkcs8", ".p8");
        mapping.put("application/vnd.pocketlearn", ".plf");
        mapping.put("image/x-portable-anymap", ".pnm");
        mapping.put("image/x-portable-bitmap", ".pbm");
        mapping.put("application/x-font-pcf", ".pcf");
        mapping.put("application/font-tdpfr", ".pfr");
        mapping.put("application/x-chess-pgn", ".pgn");
        mapping.put("image/x-portable-graymap", ".pgm");
        mapping.put("image/png", ".png");
        mapping.put("image/x-citrix-png", ".png");
        mapping.put("image/x-png", ".png");
        mapping.put("image/x-portable-pixmap", ".ppm");
        mapping.put("application/pskc+xml", ".pskcxml");
        mapping.put("application/vnd.ctc-posml", ".pml");
        mapping.put("application/postscript", ".ai");
        mapping.put("application/x-font-type1", ".pfa");
        mapping.put("application/vnd.powerbuilder6", ".pbd");
        mapping.put("application/pgp-encrypted", ".pgp");
        mapping.put("application/pgp-signature", ".pgp");
        mapping.put("application/vnd.previewsystems.box", ".box");
        mapping.put("application/vnd.pvi.ptid1", ".ptid");
        mapping.put("application/pls+xml", ".pls");
        mapping.put("application/vnd.pg.format", ".str");
        mapping.put("application/vnd.pg.osasli", ".ei6");
        mapping.put("text/prs.lines.tag", ".dsc");
        mapping.put("application/x-font-linux-psf", ".psf");
        mapping.put("application/vnd.publishare-delta-tree", ".qps");
        mapping.put("application/vnd.pmi.widget", ".wg");
        mapping.put("application/vnd.quark.quarkxpress", ".qxd");
        mapping.put("application/vnd.epson.esf", ".esf");
        mapping.put("application/vnd.epson.msf", ".msf");
        mapping.put("application/vnd.epson.ssf", ".ssf");
        mapping.put("application/vnd.epson.quickanime", ".qam");
        mapping.put("application/vnd.intu.qfx", ".qfx");
        mapping.put("video/quicktime", ".qt");
        mapping.put("application/x-rar-compressed", ".rar");
        mapping.put("audio/x-pn-realaudio", ".ram");
        mapping.put("audio/x-pn-realaudio-plugin", ".rmp");
        mapping.put("application/rsd+xml", ".rsd");
        mapping.put("application/vnd.rn-realmedia", ".rm");
        mapping.put("application/vnd.realvnc.bed", ".bed");
        mapping.put("application/vnd.recordare.musicxml", ".mxl");
        mapping.put("application/vnd.recordare.musicxml+xml", ".musicxml");
        mapping.put("application/relax-ng-compact-syntax", ".rnc");
        mapping.put("application/vnd.data-vision.rdz", ".rdz");
        mapping.put("application/rdf+xml", ".rdf");
        mapping.put("application/vnd.cloanto.rp9", ".rp9");
        mapping.put("application/vnd.jisp", ".jisp");
        mapping.put("application/rtf", ".rtf");
        mapping.put("text/richtext", ".rtx");
        mapping.put("application/vnd.route66.link66+xml", ".link66");
        mapping.put("application/rss+xml", ".rss");
        mapping.put("application/shf+xml", ".shf");
        mapping.put("application/vnd.sailingtracker.track", ".st");
        mapping.put("image/svg+xml", ".svg");
        mapping.put("application/vnd.sus-calendar", ".sus");
        mapping.put("application/sru+xml", ".sru");
        mapping.put("application/set-payment-initiation", ".setpay");
        mapping.put("application/set-registration-initiation", ".setreg");
        mapping.put("application/vnd.sema", ".sema");
        mapping.put("application/vnd.semd", ".semd");
        mapping.put("application/vnd.semf", ".semf");
        mapping.put("application/vnd.seemail", ".see");
        mapping.put("application/x-font-snf", ".snf");
        mapping.put("application/scvp-vp-request", ".spq");
        mapping.put("application/scvp-vp-response", ".spp");
        mapping.put("application/scvp-cv-request", ".scq");
        mapping.put("application/scvp-cv-response", ".scs");
        mapping.put("application/sdp", ".sdp");
        mapping.put("text/x-setext", ".etx");
        mapping.put("video/x-sgi-movie", ".movie");
        mapping.put("application/vnd.shana.informed.formdata", ".ifm");
        mapping.put("application/vnd.shana.informed.formtemplate", ".itp");
        mapping.put("application/vnd.shana.informed.interchange", ".iif");
        mapping.put("application/vnd.shana.informed.package", ".ipk");
        mapping.put("application/thraud+xml", ".tfi");
        mapping.put("application/x-shar", ".shar");
        mapping.put("image/x-rgb", ".rgb");
        mapping.put("application/vnd.epson.salt", ".slt");
        mapping.put("application/vnd.accpac.simply.aso", ".aso");
        mapping.put("application/vnd.accpac.simply.imp", ".imp");
        mapping.put("application/vnd.simtech-mindmapper", ".twd");
        mapping.put("application/vnd.commonspace", ".csp");
        mapping.put("application/vnd.yamaha.smaf-audio", ".saf");
        mapping.put("application/vnd.smaf", ".mmf");
        mapping.put("application/vnd.yamaha.smaf-phrase", ".spf");
        mapping.put("application/vnd.smart.teacher", ".teacher");
        mapping.put("application/vnd.svd", ".svd");
        mapping.put("application/sparql-query", ".rq");
        mapping.put("application/sparql-results+xml", ".srx");
        mapping.put("application/srgs", ".gram");
        mapping.put("application/srgs+xml", ".grxml");
        mapping.put("application/ssml+xml", ".ssml");
        mapping.put("application/vnd.koan", ".skp");
        mapping.put("text/sgml", ".sgml");
        mapping.put("application/vnd.stardivision.calc", ".sdc");
        mapping.put("application/vnd.stardivision.draw", ".sda");
        mapping.put("application/vnd.stardivision.impress", ".sdd");
        mapping.put("application/vnd.stardivision.math", ".smf");
        mapping.put("application/vnd.stardivision.writer", ".sdw");
        mapping.put("application/vnd.stardivision.writer-global", ".sgl");
        mapping.put("application/vnd.stepmania.stepchart", ".sm");
        mapping.put("application/x-stuffit", ".sit");
        mapping.put("application/x-stuffitx", ".sitx");
        mapping.put("application/vnd.solent.sdkm+xml", ".sdkm");
        mapping.put("application/vnd.olpc-sugar", ".xo");
        mapping.put("audio/basic", ".au");
        mapping.put("application/vnd.wqd", ".wqd");
        mapping.put("application/vnd.symbian.install", ".sis");
        mapping.put("application/smil+xml", ".smi");
        mapping.put("application/vnd.syncml+xml", ".xsm");
        mapping.put("application/vnd.syncml.dm+wbxml", ".bdm");
        mapping.put("application/vnd.syncml.dm+xml", ".xdm");
        mapping.put("application/x-sv4cpio", ".sv4cpio");
        mapping.put("application/x-sv4crc", ".sv4crc");
        mapping.put("application/sbml+xml", ".sbml");
        mapping.put("text/tab-separated-values", ".tsv");
        mapping.put("image/tiff", ".tiff");
        mapping.put("application/vnd.tao.intent-module-archive", ".tao");
        mapping.put("application/x-tar", ".tar");
        mapping.put("application/x-tcl", ".tcl");
        mapping.put("application/x-tex", ".tex");
        mapping.put("application/x-tex-tfm", ".tfm");
        mapping.put("application/tei+xml", ".tei");
        mapping.put("text/plain", ".txt");
        mapping.put("application/vnd.spotfire.dxp", ".dxp");
        mapping.put("application/vnd.spotfire.sfs", ".sfs");
        mapping.put("application/timestamped-data", ".tsd");
        mapping.put("application/vnd.trid.tpt", ".tpt");
        mapping.put("application/vnd.triscape.mxs", ".mxs");
        mapping.put("text/troff", ".t");
        mapping.put("application/vnd.trueapp", ".tra");
        mapping.put("application/x-font-ttf", ".ttf");
        mapping.put("text/turtle", ".ttl");
        mapping.put("application/vnd.umajin", ".umj");
        mapping.put("application/vnd.uoml+xml", ".uoml");
        mapping.put("application/vnd.unity", ".unityweb");
        mapping.put("application/vnd.ufdl", ".ufd");
        mapping.put("text/uri-list", ".uri");
        mapping.put("application/vnd.uiq.theme", ".utz");
        mapping.put("application/x-ustar", ".ustar");
        mapping.put("text/x-uuencode", ".uu");
        mapping.put("text/x-vcalendar", ".vcs");
        mapping.put("text/x-vcard", ".vcf");
        mapping.put("application/x-cdlink", ".vcd");
        mapping.put("application/vnd.vsf", ".vsf");
        mapping.put("model/vrml", ".wrl");
        mapping.put("application/vnd.vcx", ".vcx");
        mapping.put("model/vnd.mts", ".mts");
        mapping.put("model/vnd.vtu", ".vtu");
        mapping.put("application/vnd.visionary", ".vis");
        mapping.put("video/vnd.vivo", ".viv");
        mapping.put("application/ccxml+xml,", ".ccxml");
        mapping.put("application/voicexml+xml", ".vxml");
        mapping.put("application/x-wais-source", ".src");
        mapping.put("application/vnd.wap.wbxml", ".wbxml");
        mapping.put("image/vnd.wap.wbmp", ".wbmp");
        mapping.put("audio/x-wav", ".wav");
        mapping.put("application/davmount+xml", ".davmount");
        mapping.put("application/x-font-woff", ".woff");
        mapping.put("application/wspolicy+xml", ".wspolicy");
        mapping.put("image/webp", ".webp");
        mapping.put("application/vnd.webturbo", ".wtb");
        mapping.put("application/widget", ".wgt");
        mapping.put("application/winhlp", ".hlp");
        mapping.put("text/vnd.wap.wml", ".wml");
        mapping.put("text/vnd.wap.wmlscript", ".wmls");
        mapping.put("application/vnd.wap.wmlscriptc", ".wmlsc");
        mapping.put("application/vnd.wordperfect", ".wpd");
        mapping.put("application/vnd.wt.stf", ".stf");
        mapping.put("application/wsdl+xml", ".wsdl");
        mapping.put("image/x-xbitmap", ".xbm");
        mapping.put("image/x-xpixmap", ".xpm");
        mapping.put("image/x-xwindowdump", ".xwd");
        mapping.put("application/x-x509-ca-cert", ".der");
        mapping.put("application/x-xfig", ".fig");
        mapping.put("application/xhtml+xml", ".xhtml");
        mapping.put("application/xml", ".xml");
        mapping.put("application/xcap-diff+xml", ".xdf");
        mapping.put("application/xenc+xml", ".xenc");
        mapping.put("application/patch-ops-error+xml", ".xer");
        mapping.put("application/resource-lists+xml", ".rl");
        mapping.put("application/rls-services+xml", ".rs");
        mapping.put("application/resource-lists-diff+xml", ".rld");
        mapping.put("application/xslt+xml", ".xslt");
        mapping.put("application/xop+xml", ".xop");
        mapping.put("application/x-xpinstall", ".xpi");
        mapping.put("application/xspf+xml", ".xspf");
        mapping.put("application/vnd.mozilla.xul+xml", ".xul");
        mapping.put("chemical/x-xyz", ".xyz");
        mapping.put("text/yaml", ".yaml");
        mapping.put("application/yang", ".yang");
        mapping.put("application/yin+xml", ".yin");
        mapping.put("application/vnd.zul", ".zir");
        mapping.put("application/zip", ".zip");
        mapping.put("application/vnd.handheld-entertainment+xml", ".zmm");
        mapping.put("application/vnd.zzazz.deck+xml", ".zaz");

        return mapping;
    }


    @TargetApi(19)
    public static String getRealPathFromURI(final Context context, final Uri uri) {
        String path = "";
        try {
            path = processUri(context, uri);
        } catch (Exception exception) {
            exception.printStackTrace();
        }
        if (TextUtils.isEmpty(path)) {
            path = copyFile(context, uri);
        }
        return path;
    }

    private static String processUri(Context context, Uri uri) {
        final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
        String path = "";
        // DocumentProvider
        if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                if ("primary".equalsIgnoreCase(type)) {
                    path = Environment.getExternalStorageDirectory() + "/" + split[1];
                }
            } else if (isDownloadsDocument(uri)) { // DownloadsProvider
                final String id = DocumentsContract.getDocumentId(uri);
                //Starting with Android O, this "id" is not necessarily a long (row number),
                //but might also be a "raw:/some/file/path" URL
                if (id != null && id.startsWith("raw:/")) {
                    Uri rawuri = Uri.parse(id);
                    path = rawuri.getPath();
                } else {
                    String[] contentUriPrefixesToTry = new String[]{
                            "content://downloads/public_downloads",
                            "content://downloads/my_downloads"
                    };
                    for (String contentUriPrefix : contentUriPrefixesToTry) {
                        final Uri contentUri = ContentUris.withAppendedId(
                                Uri.parse(contentUriPrefix), Long.valueOf(id));
                        path = getDataColumn(context, contentUri, null, null);
                        if (!TextUtils.isEmpty(path)) {
                            break;
                        }
                    }
                }
            } else if (isMediaDocument(uri)) { // MediaProvider
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];
                Uri contentUri = null;
                if ("image".equals(type)) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                } else if ("video".equals(type)) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                } else if ("audio".equals(type)) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                }

                final String selection = "_id=?";
                final String[] selectionArgs = new String[] {
                        split[1]
                };

                path = getDataColumn(context, contentUri, selection, selectionArgs);
            }  else if ("content".equalsIgnoreCase(uri.getScheme())) {
                path = getDataColumn(context, uri, null, null);
            }
        } else if ("content".equalsIgnoreCase(uri.getScheme())) { // MediaStore (and general)
            path = getDataColumn(context, uri, null, null);
        } else if ("file".equalsIgnoreCase(uri.getScheme())) { // File
            path = uri.getPath();
        }
        return path;
    }

    static String copyFile(Context context, Uri uri) {
        try {
            InputStream attachment = context.getContentResolver().openInputStream(uri);
            if (attachment != null) {
                String filename = getContentName(context.getContentResolver(), uri);
                if (filename != null) {
                    File file = new File(context.getCacheDir(), filename);
                    FileOutputStream tmp = new FileOutputStream(file);
                    byte[] buffer = new byte[1024];
                    while (attachment.read(buffer) > 0) {
                        tmp.write(buffer);
                    }
                    tmp.close();
                    attachment.close();
                    return file.getAbsolutePath();
                }
            }
        } catch (Exception e) {
            return null;
        }
        return null;
    }

    private static String getContentName(ContentResolver resolver, Uri uri) {
        Cursor cursor = resolver.query(uri, null, null, null, null);
        if (cursor != null) {
            cursor.moveToFirst();
            int nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME);
            if (nameIndex >= 0) {
                String name = cursor.getString(nameIndex);
                cursor.close();
                return name;
            }
        }
        return null;
    }

    /**
     * Get the value of the data column for this Uri. This is useful for
     * MediaStore Uris, and other file-based ContentProviders.
     *
     * @param context The context.
     * @param uri The Uri to query.
     * @param selection (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     */
    public static String getDataColumn(Context context, Uri uri, String selection,
                                       String[] selectionArgs) {
        Cursor cursor = null;
        String result = null;
        final String column = "_data";
        final String[] projection = { column };
        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                    null);
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(column);
                result = cursor.getString(index);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
            return null;
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return result;
    }


    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    public static boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    public static boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    public static boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }
}
