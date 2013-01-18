 #!/usr/bin/perl
 
 use Net::LDAP;
 
 # Set LDAP bind information here. Start with http://search.cpan.org/~gbarr/perl-ldap/lib/Net/LDAP.pod for more info on Net::LDAP
 
 my $ldapserver = "localhost";
 my $ldapversion = 3;
 my $ldapuser = "uid=binduser,dc=domain,dc=com";
 my $ldapbase = "ou=Contacts,dc=domain,dc=com";
 my $ldappass = "password";
 
 sub LDAPsearch {
     my ($ldap,$searchString,$attrs,$base) = @_;
     my $result = $ldap->search ( base => "$base",
       scope => "sub",
       filter => "$searchString",
       attrs   =>  $attrs
   );
 }
 
 # This is where you would specify a different search field 
 my @attribs = ('cn', 'destinationIndicator');
 
 # One of the first things I ran into was whether to call my script from an extension or at the 
 # dialplan. From the dialplan, you return a full XML dialplan in $XML_STRING as it is in the 
 # mod_perl docs. Try as I might, I never got Freeswitch to act on my dialplan, so I call the
 # script from my dialplan as shown later in this wiki page. But, the takeaway is, 
 # if you generate a dialplan and call the script from perl.conf.xml, you have to use 
 # $params->getHeader. If you call the script as an application from an exception, you have to 
 # use $session->getVariable. 
 #my $number=$params->getHeader("Caller-Caller-ID-Number");
 my $number=$session->getVariable("caller_id_number");
 
 # I log the incoming number to the console to be sure my script is being called
 freeswitch::console_log("info", "Handling call from $number\n");
 
 # This will match on homePhone, mobile and telephoneNumber records in LDAP. You could also add 
 # the relevant fields for FAX numbers, or anything else that's in your schema. I used loose
 # matching because that handles the case where a number appears as 1234567890 to Freeswitch, but 
 # could be entered as 123-456-7890 in LDAP. 
 my $searchstring="(|(homePhone~=$number)(mobile~=$number)(telephoneNumber~=$number))";
 
 # Connect to the LDAP server and run our query
 my $ldap = Net::LDAP->new ( $ldapserver ) or die "$@";
 $ldap->bind ( $ldapuser, password => $ldappass, version => $ldapversion ) or die "$@";
 my $search = LDAPsearch ($ldap, $searchstring, \@attribs, $ldapbase ) or die "$@";
 my @entries = $search->entries;
 my ($name, $dest);
 
 # This could be done better - we simply grab the name of an extension out of LDAP, 
 # and transfer the call there. There's no handling of oddities in the LDAP search result
 # and executing on data straight out of LDAP probably isn't the safest thing ever. 
 # If we have an extension listed in the contact's entry, we send the caller there, 
 # otherwise we send it to the greylist extension. 
 if (@entries) {
       $name=$entries[0]->get_value('cn');
       $dest=$entries[0]->get_value('destinationIndicator');
 } else {  
       $name = "Unknown";
       $dest="greylist";
 }
 
 # Freeswitch picks up the call here, sets the CID name and number (which doesn't seem to have 
 # an effect for me, and transfers the call to the extension the script picked.  
 $session->answer();
 $session->setVariable("effective_caller_id_number", $number);
 $session->setVariable("effective_caller_id_name", $name);
 $session->transfer($dest, "XML", "default");
 
 # Freeswitch will be mad if you don't return a true value. 
 1;

Now, we need to add entries to the XML files. Starting with the default configuration files from when I compiled Freeswitch, I added this to conf/dialplan/public.xml:

 <extension name="ldap_switched_in">
     <condition field="destination_number" expression="MYDID">
       <action application="perl" data="ldaplookup.pl"/>
     </condition>
 </extension>
 #!/usr/bin/perl
 
 use Net::LDAP;
 
 # Set LDAP bind information here. Start with http://search.cpan.org/~gbarr/perl-ldap/lib/Net/LDAP.pod for more info on Net::LDAP
 
 my $ldapserver = "localhost";
 my $ldapversion = 3;
 my $ldapuser = "uid=binduser,dc=domain,dc=com";
 my $ldapbase = "ou=Contacts,dc=domain,dc=com";
 my $ldappass = "password";
 
 sub LDAPsearch {
     my ($ldap,$searchString,$attrs,$base) = @_;
     my $result = $ldap->search ( base => "$base",
       scope => "sub",
       filter => "$searchString",
       attrs   =>  $attrs
   );
 }
 
 # This is where you would specify a different search field 
 my @attribs = ('cn', 'destinationIndicator');
 
 # One of the first things I ran into was whether to call my script from an extension or at the 
 # dialplan. From the dialplan, you return a full XML dialplan in $XML_STRING as it is in the 
 # mod_perl docs. Try as I might, I never got Freeswitch to act on my dialplan, so I call the
 # script from my dialplan as shown later in this wiki page. But, the takeaway is, 
 # if you generate a dialplan and call the script from perl.conf.xml, you have to use 
 # $params->getHeader. If you call the script as an application from an exception, you have to 
 # use $session->getVariable. 
 #my $number=$params->getHeader("Caller-Caller-ID-Number");
 my $number=$session->getVariable("caller_id_number");
 
 # I log the incoming number to the console to be sure my script is being called
 freeswitch::console_log("info", "Handling call from $number\n");
 
 # This will match on homePhone, mobile and telephoneNumber records in LDAP. You could also add 
 # the relevant fields for FAX numbers, or anything else that's in your schema. I used loose
 # matching because that handles the case where a number appears as 1234567890 to Freeswitch, but 
 # could be entered as 123-456-7890 in LDAP. 
 my $searchstring="(|(homePhone~=$number)(mobile~=$number)(telephoneNumber~=$number))";
 
 # Connect to the LDAP server and run our query
 my $ldap = Net::LDAP->new ( $ldapserver ) or die "$@";
 $ldap->bind ( $ldapuser, password => $ldappass, version => $ldapversion ) or die "$@";
 my $search = LDAPsearch ($ldap, $searchstring, \@attribs, $ldapbase ) or die "$@";
 my @entries = $search->entries;
 my ($name, $dest);
 
 # This could be done better - we simply grab the name of an extension out of LDAP, 
 # and transfer the call there. There's no handling of oddities in the LDAP search result
 # and executing on data straight out of LDAP probably isn't the safest thing ever. 
 # If we have an extension listed in the contact's entry, we send the caller there, 
 # otherwise we send it to the greylist extension. 
 if (@entries) {
       $name=$entries[0]->get_value('cn');
       $dest=$entries[0]->get_value('destinationIndicator');
 } else {  
       $name = "Unknown";
       $dest="greylist";
 }
 
 # Freeswitch picks up the call here, sets the CID name and number (which doesn't seem to have 
 # an effect for me, and transfers the call to the extension the script picked.  
 $session->answer();
 $session->setVariable("effective_caller_id_number", $number);
 $session->setVariable("effective_caller_id_name", $name);
 $session->transfer($dest, "XML", "default");
 
 # Freeswitch will be mad if you don't return a true value. 
 1;

Now, we need to add entries to the XML files. Starting with the default configuration files from when I compiled Freeswitch, I added this to conf/dialplan/public.xml:

 <extension name="ldap_switched_in">
     <condition field="destination_number" expression="MYDID">
       <action application="perl" data="ldaplookup.pl"/>
     </condition>
 </extension>

