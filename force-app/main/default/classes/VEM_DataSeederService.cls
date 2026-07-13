/**
 * @description Service class for seeding all Velmend Events data including Users, Organizations, 
 * Professional Person Accounts, Affiliations, Products, Events, Consultants/Speakers, 
 * Attendees, and Expenses. Implements idempotent data creation using VEM_Seed_Key__c.
 * @author Velmend Events Team
 */
public with sharing class VEM_DataSeederService {
    

    /**
     * Method to create Products
     * @return String Summary of created records or error details
     */
    @AuraEnabled
    public static String seedProducts() {
      
            Integer productCreated = 0;
            Integer productSkipped = 0;
            List<String> productErrorMessages = new List<String>();
            
        List<VEM_Product__c> productsToCreate = new List<VEM_Product__c>();
        
        // Create sample products
        VEM_Product__c product1 = new VEM_Product__c(
                VEM_Name__c = 'OncoBlaster X',
            VEM_Area__c = 'Oncology',
                VEM_Technology__c = 'Advanced nanotherapy',
                VEM_Indication__c = 'ALL & AML in patients ≥12 years',
                VEM_Key_Metrics__c = '66% 2 year survival rate'
        );
        productsToCreate.add(product1);
        
        VEM_Product__c product2 = new VEM_Product__c(
                VEM_Name__c = 'NeuroNova Core',
            VEM_Area__c = 'Neurology',
                VEM_Technology__c = 'CRISPR-guided exosome therapy',
                VEM_Indication__c = 'ARRMS with active lesions',
                VEM_Key_Metrics__c = '30% Brain Lesion Reduction'
        );
        productsToCreate.add(product2);
        
            // Create the products
        if (!productsToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(productsToCreate, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                }
            }
            
            String summary = 'Products: created=' + productCreated + ', skipped=' + productSkipped;
            if (!productErrorMessages.isEmpty()) {
                summary += ' | Product Errors: ' + String.join(productErrorMessages, ' | ');
            }
            return 'ran product creation';
        
    }
    
    /**
     * Method to delete all Products
     * @return String Success message or error details
     */
    @AuraEnabled
    public static String deleteProducts() {
            Integer productDeleted = 0;
            Integer productDeleteFailed = 0;
            List<String> deleteErrors = new List<String>();
            
            // Delete Products
            List<VEM_Product__c> productsToDelete = [SELECT Id, Name FROM VEM_Product__c];
            System.debug('Found ' + productsToDelete.size() + ' products to delete');
            if (!productsToDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(productsToDelete, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.DeleteResult result = results[i];
                    if (result.isSuccess()) {
                        productDeleted++;
                    } 
                }
            }
            return 'ran delete products';
        
    }
   

    
    /**
     * Method to create Consultants linked to Professional Accounts
     * Creates 10 consultants: 5 from East region, 5 from West region
     * @return String Summary of created records or error details
     */
    @AuraEnabled
    public static String seedConsultantsPublic() {
     
            Integer consultantCreated = 0;
            Integer consultantSkipped = 0;
            List<String> consultantErrorMessages = new List<String>();
            
            // Get Professional Accounts (HCPs) by region
            // East region HCPs - from S.H.I.E.L.D, Daily Planet, Wayne Enterprises
            Set<String> eastFirstNames = new Set<String>{'Steve', 'Natasha', 'Bruce', 'Clark', 'Kara', 'Barry', 'Diana', 'Kate'};
            List<Account> eastHcps = [
                SELECT Id, FirstName, LastName 
                FROM Account 
                WHERE RecordType.Name = 'Professional' 
                AND FirstName IN :eastFirstNames
                LIMIT 10
            ];
            
            // West region HCPs - from Stark Industries, Oscorp, Hydra
            // Note: T'Challa might be stored differently, so we'll query by LastName too
            Set<String> westFirstNames = new Set<String>{'Tony', 'Peter', 'Carol', 'Wanda', 'Stephen', 'Reed', 'Arthur', 'Clint'};
            Set<String> westLastNames = new Set<String>{'Stark', 'Parker', 'Danvers', 'Maximoff', 'Strange', 'Richards', 'Curry', 'Barton', 'Challa'};
            List<Account> westHcps = [
                SELECT Id, FirstName, LastName 
                FROM Account 
                WHERE RecordType.Name = 'Professional' 
                AND (FirstName IN :westFirstNames OR LastName IN :westLastNames)
                LIMIT 10
            ];
            
            // Map of superhero names to bios
            Map<String, String> superheroBios = new Map<String, String>{
                'Steve Rogers' => 'Captain America - World War II veteran and super-soldier, expert in leadership and strategic planning. Decades of experience in military operations and team coordination.',
                'Natasha Romanoff' => 'Black Widow - Highly trained spy and assassin with expertise in intelligence gathering, combat tactics, and undercover operations.',
                'Bruce Banner' => 'The Hulk - Brilliant nuclear physicist and gamma radiation expert. Renowned researcher in advanced scientific applications.',
                'Clark Kent' => 'Superman - Investigative journalist with a strong sense of justice. Expert in uncovering truth and protecting the innocent.',
                'Kara Danvers' => 'Supergirl - Kryptonian hero with extensive experience in crisis management and protecting Earth from extraterrestrial threats.',
                'Barry Allen' => 'The Flash - Forensic scientist with super-speed abilities. Expert in crime scene analysis and rapid response situations.',
                'Tony Stark' => 'Iron Man - Genius inventor and CEO of Stark Industries. Leading expert in advanced technology, engineering, and innovation.',
                'Peter Parker' => 'Spider-Man - Brilliant scientist and photographer. Expert in biochemistry and agile problem-solving in high-stakes situations.',
                'Carol Danvers' => 'Captain Marvel - Former Air Force pilot turned cosmic hero. Expert in aerial combat and intergalactic diplomacy.',
                'Wanda Maximoff' => 'Scarlet Witch - Master of chaos magic and reality manipulation. Expert in mystical arts and dimensional physics.',
                'T\'Challa' => 'Black Panther - King of Wakanda and protector of advanced technology. Expert in leadership, diplomacy, and cutting-edge science.',
                'Stephen Strange' => 'Doctor Strange - Master of the Mystic Arts and former neurosurgeon. Expert in mystical dimensions and medical expertise.',
                'Reed Richards' => 'Mister Fantastic - Brilliant scientist and leader of the Fantastic Four. Expert in theoretical physics and dimensional research.',
                'Arthur Curry' => 'Aquaman - King of Atlantis and master of the seas. Expert in marine biology and underwater operations.',
                'Clint Barton' => 'Hawkeye - Master archer and SHIELD agent. Expert in precision targeting and tactical operations.'
            };
            
            List<VEM_Consultant__c> consultantsToCreate = new List<VEM_Consultant__c>();
            
            // Create 5 East region consultants
            Integer eastCount = 0;
            for (Account hcp : eastHcps) {
                if (eastCount >= 5) break;
                String fullName = (hcp.FirstName != null ? hcp.FirstName : '') + ' ' + (hcp.LastName != null ? hcp.LastName : '');
                fullName = fullName.trim();
                
                // Handle special case for T'Challa
                if (hcp.LastName != null && hcp.LastName.contains('Challa')) {
                    fullName = 'T\'Challa';
                }
                
                String bio = superheroBios.get(fullName);
                if (bio == null) {
                    bio = fullName + ' is a highly qualified professional with extensive expertise in their field.';
                }
                
                // Generate random FMV between 500 and 1000
                Integer fmv = 500 + Math.mod(Math.abs(Crypto.getRandomInteger()), 501);
                
                VEM_Consultant__c consultant = new VEM_Consultant__c(
                    VEM_Professional_Account__c = hcp.Id,
                    VEM_Status__c = 'Eligible',
                    VEM_Bio__c = bio,
                    VEM_FMV__c = fmv
                );
                consultantsToCreate.add(consultant);
                eastCount++;
            }
            
            // Create 5 West region consultants
            Integer westCount = 0;
            for (Account hcp : westHcps) {
                if (westCount >= 5) break;
                String fullName = (hcp.FirstName != null ? hcp.FirstName : '') + ' ' + (hcp.LastName != null ? hcp.LastName : '');
                fullName = fullName.trim();
                
                // Handle special case for T'Challa
                if (hcp.LastName != null && hcp.LastName.contains('Challa')) {
                    fullName = 'T\'Challa';
                }
                
                String bio = superheroBios.get(fullName);
                if (bio == null) {
                    bio = fullName + ' is a highly qualified professional with extensive expertise in their field.';
                }
                
                // Generate random FMV between 500 and 1000
                Integer fmv = 500 + Math.mod(Math.abs(Crypto.getRandomInteger()), 501);
                
                VEM_Consultant__c consultant = new VEM_Consultant__c(
                    VEM_Professional_Account__c = hcp.Id,
                    VEM_Status__c = 'Eligible',
                    VEM_Bio__c = bio,
                    VEM_FMV__c = fmv
                );
                consultantsToCreate.add(consultant);
                westCount++;
            }
            
            // Insert consultants
            if (!consultantsToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(consultantsToCreate, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                }
            }
            
       
            return 'ran consultant creation';
       
    }
    
    /**
     * Method to delete all Consultants
     * @return String Success message or error details
     */
    @AuraEnabled
    public static String deleteConsultants() {
      
            Integer consultantDeleted = 0;
            Integer consultantDeleteFailed = 0;
            List<String> deleteErrors = new List<String>();
            
            // Delete Consultants
            List<VEM_Consultant__c> consultantsToDelete = [SELECT Id FROM VEM_Consultant__c];
            System.debug('Found ' + consultantsToDelete.size() + ' consultants to delete');
            if (!consultantsToDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(consultantsToDelete, false);
            }
 
            return 'ran delete consultants';
       
    }
    
    
    /**
     * Seeds Organizations and Professional Person Accounts with Affiliations
     * Creates 6 Organization Accounts, 18 HCP Person Accounts, and their affiliations
     * Uses deterministic VEM_Seed_Key__c for idempotency
     * @return String Summary of created/skipped records
     */
    @AuraEnabled
    public static String seedAccountsAndAffiliations() {
        
            // Track counts
            Integer orgCreated = 0;
            Integer orgSkipped = 0;
            Integer hcpCreated = 0;
            Integer hcpSkipped = 0;
            Integer affCreated = 0;
            Integer affSkipped = 0;
            Integer orgAddrCreated = 0;
            Integer orgAddrSkipped = 0;
            Integer hcpAddrCreated = 0;
            Integer hcpAddrSkipped = 0;
            // Collect detailed error messages so they can surface in the UI
            List<String> hcpErrorMessages = new List<String>();
            List<String> affiliationErrorMessages = new List<String>();
            List<String> orgAddressErrorMessages = new List<String>();
            List<String> hcpAddressErrorMessages = new List<String>();

            // Get RecordType IDs first
            Map<String, Id> recordTypeIds = new Map<String, Id>();
            for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account']) {
                recordTypeIds.put(rt.Name, rt.Id);
            }

            // Maps to store existing records by seed key
            Map<String, Account> existingOrgs = new Map<String, Account>();
            Map<String, Account> existingHcps = new Map<String, Account>();

            // Get existing organizations by seed key (using record type, since seed key field may not exist)
            List<Account> existingOrgRecords = [SELECT Id FROM Account WHERE RecordType.Name = 'Organization'];
            for (Account acc : existingOrgRecords) {
                existingOrgs.put(String.valueOf(acc.Id), acc);
            }

            // Get existing person accounts (using Id-based map since VEM_Seed_Key__c may not exist)
            List<Account> existingHcpRecords = [SELECT Id FROM Account WHERE RecordType.Name = 'Professional'];
            for (Account acc : existingHcpRecords) {
                existingHcps.put(String.valueOf(acc.Id), acc);
            }

            // Create Organizations
            List<Account> orgsToCreate = new List<Account>();
            Map<String, Account> orgMap = new Map<String, Account>();

            // S.H.I.E.L.D (East)
            String orgSeedKey1 = 'ORG-SHIELD';
            if (true) {
                Account org1 = new Account(
                    Name         = 'S.H.I.E.L.D',
                    RecordTypeId = recordTypeIds.get('Organization'),
                    VEM_Region__c = 'East'
                );
                orgsToCreate.add(org1);
                orgMap.put(orgSeedKey1, org1);
            } else {
                orgSkipped++;
            }

            // Daily Planet (East)
            String orgSeedKey2 = 'ORG-DAILYPLANET';
            if (true) {
                Account org2 = new Account(
                    Name         = 'Daily Planet',
                    RecordTypeId = recordTypeIds.get('Organization'),
                    VEM_Region__c = 'East'
                );
                orgsToCreate.add(org2);
                orgMap.put(orgSeedKey2, org2);
            } else {
                orgSkipped++;
            }

            // Wayne Enterprises (East)
            String orgSeedKey3 = 'ORG-WAYNE';
            if (true) {
                Account org3 = new Account(
                    Name         = 'Wayne Enterprises',
                    RecordTypeId = recordTypeIds.get('Organization'),
                    VEM_Region__c = 'East'
                );
                orgsToCreate.add(org3);
                orgMap.put(orgSeedKey3, org3);
            } else {
                orgSkipped++;
            }

            // Stark Industries (West)
            String orgSeedKey4 = 'ORG-STARK';
            if (true) {
                Account org4 = new Account(
                    Name         = 'Stark Industries',
                    RecordTypeId = recordTypeIds.get('Organization'),
                    VEM_Region__c = 'West'
                );
                orgsToCreate.add(org4);
                orgMap.put(orgSeedKey4, org4);
            } else {
                orgSkipped++;
            }

            // Oscorp (West)
            String orgSeedKey5 = 'ORG-OSCORP';
            if (true) {
                Account org5 = new Account(
                    Name         = 'Oscorp',
                    RecordTypeId = recordTypeIds.get('Organization'),
                    VEM_Region__c = 'West'
                );
                orgsToCreate.add(org5);
                orgMap.put(orgSeedKey5, org5);
            } else {
                orgSkipped++;
            }

            // Hydra (West)
            String orgSeedKey6 = 'ORG-HYDRA';
            if (true) {
                Account org6 = new Account(
                    Name         = 'Hydra',
                    RecordTypeId = recordTypeIds.get('Organization'),
                    VEM_Region__c = 'West'
                );
                orgsToCreate.add(org6);
                orgMap.put(orgSeedKey6, org6);
            } else {
                orgSkipped++;
            }

            // Insert organizations if needed
            if (!orgsToCreate.isEmpty()) {
                Database.SaveResult[] orgResults = Database.insert(orgsToCreate, false);
                for (Database.SaveResult result : orgResults) {
                    if (result.isSuccess()) {
                        orgCreated++;
                    } else {
                        System.debug('Error creating organization: ' + result.getErrors()[0].getMessage());
                    }
                }
            }

            // Now create the person accounts
            List<Account> hcpAccountsToCreate = new List<Account>();
            Map<String, Account> hcpMap = new Map<String, Account>();

            // East Organizations
            // S.H.I.E.L.D
            String[] eastHcpNames = new String[] {'Steve Rogers', 'Natasha Romanoff', 'Bruce Banner'};
            for (Integer i = 0; i < eastHcpNames.size(); i++) {
                String[] nameParts = eastHcpNames[i].split(' ');
                // Handle names that may not have both first and last segments
                String firstName = (nameParts.size() > 0) ? nameParts[0] : '';
                String lastName  = (nameParts.size() > 1) ? nameParts[nameParts.size() - 1] : firstName;
                // Use deterministic seed key based only on last name so it matches affiliation definitions (e.g., HCP-ROGERS)
                String hcpSeedKey = 'HCP-' + lastName.toUpperCase();
                
                Account hcp = new Account(
                    FirstName    = firstName,
                    LastName     = lastName,
                    RecordTypeId = recordTypeIds.get('Professional'),
                    VEM_Region__c = 'East'
                );
                
                // Add random credential
                String[] credentials = new String[] {'MD', 'RN', 'NP', 'PA', 'PharmD'};
                // Fix for random index out of bounds error - use a more robust approach
                Integer randomIndex = Math.mod(Math.abs(System.now().getTime().intValue() + i), credentials.size());
                String randomCredential = credentials[randomIndex];
                hcp.put('Credential__c', randomCredential);
                hcpAccountsToCreate.add(hcp);
                hcpMap.put(hcpSeedKey, hcp);
            }

            // Daily Planet
            String[] dailyPlanetHcpNames = new String[] {'Clark Kent', 'Kara Danvers', 'Barry Allen'};
            for (Integer i = 0; i < dailyPlanetHcpNames.size(); i++) {
                String[] nameParts = dailyPlanetHcpNames[i].split(' ');
                String firstName = (nameParts.size() > 0) ? nameParts[0] : '';
                String lastName  = (nameParts.size() > 1) ? nameParts[nameParts.size() - 1] : firstName;
                String hcpSeedKey = 'HCP-' + lastName.toUpperCase();
                
                Account hcp = new Account(
                    FirstName    = firstName,
                    LastName     = lastName,
                    RecordTypeId = recordTypeIds.get('Professional'),
                    VEM_Region__c = 'East'
                );
                
                // Add random credential
                String[] credentials = new String[] {'MD', 'RN', 'NP', 'PA', 'PharmD'};
                Integer randomIndex = Math.mod(Math.abs(System.now().getTime().intValue() + i), credentials.size());
                String randomCredential = credentials[randomIndex];
                hcp.put('Credential__c', randomCredential);
                hcpAccountsToCreate.add(hcp);
                hcpMap.put(hcpSeedKey, hcp);
            }

            // Wayne Enterprises
            String[] wayneHcpNames = new String[] {'Bruce Wayne', 'Diana Prince', 'Kate Kane'};
            for (Integer i = 0; i < wayneHcpNames.size(); i++) {
                String[] nameParts = wayneHcpNames[i].split(' ');
                String firstName = (nameParts.size() > 0) ? nameParts[0] : '';
                String lastName  = (nameParts.size() > 1) ? nameParts[nameParts.size() - 1] : firstName;
                String hcpSeedKey = 'HCP-' + lastName.toUpperCase();
                
                Account hcp = new Account(
                    FirstName    = firstName,
                    LastName     = lastName,
                    RecordTypeId = recordTypeIds.get('Professional'),
                    VEM_Region__c = 'East'
                );
                
                // Add random credential
                String[] credentials = new String[] {'MD', 'RN', 'NP', 'PA', 'PharmD'};
                Integer randomIndex = Math.mod(Math.abs(System.now().getTime().intValue() + i + 20), credentials.size());
                String randomCredential = credentials[randomIndex];
                hcp.put('Credential__c', randomCredential);
                hcpAccountsToCreate.add(hcp);
                hcpMap.put(hcpSeedKey, hcp);
            }

            // West Organizations
            // Stark Industries
            String[] starkHcpNames = new String[] {'Tony Stark', 'Peter Parker', 'Carol Danvers'};
            for (Integer i = 0; i < starkHcpNames.size(); i++) {
                String[] nameParts = starkHcpNames[i].split(' ');
                String firstName = (nameParts.size() > 0) ? nameParts[0] : '';
                String lastName  = (nameParts.size() > 1) ? nameParts[nameParts.size() - 1] : firstName;
                String hcpSeedKey = 'HCP-' + lastName.toUpperCase();
                
                Account hcp = new Account(
                    FirstName    = firstName,
                    LastName     = lastName,
                    RecordTypeId = recordTypeIds.get('Professional'),
                    VEM_Region__c = 'West'
                );
                
                // Add random credential
                String[] credentials = new String[] {'MD', 'RN', 'NP', 'PA', 'PharmD'};
                Integer randomIndex = Math.mod(Math.abs(System.now().getTime().intValue() + i + 30), credentials.size());
                String randomCredential = credentials[randomIndex];
                hcp.put('Credential__c', randomCredential);
                hcpAccountsToCreate.add(hcp);
                hcpMap.put(hcpSeedKey, hcp);
            }

            // Oscorp
            String[] oscorpHcpNames = new String[] {'Wanda Maximoff', 'T\'Challa', 'Stephen Strange'};
            for (Integer i = 0; i < oscorpHcpNames.size(); i++) {
                String[] nameParts = oscorpHcpNames[i].split(' ');
                String firstName = (nameParts.size() > 0) ? nameParts[0] : '';
                String lastName  = (nameParts.size() > 1) ? nameParts[nameParts.size() - 1] : firstName;
                String hcpSeedKey = 'HCP-' + lastName.toUpperCase();
                
                Account hcp = new Account(
                    FirstName    = firstName,
                    LastName     = lastName,
                    RecordTypeId = recordTypeIds.get('Professional'),
                    VEM_Region__c = 'West'
                );
                
                // Add random credential
                String[] credentials = new String[] {'MD', 'RN', 'NP', 'PA', 'PharmD'};
                Integer randomIndex = Math.mod(System.now().getTime().intValue() + i + 40, credentials.size());
                String randomCredential = credentials[randomIndex];
                hcp.put('Credential__c', randomCredential);
                hcpAccountsToCreate.add(hcp);
                hcpMap.put(hcpSeedKey, hcp);
            }

            // Hydra
            String[] hydraHcpNames = new String[] {'Reed Richards', 'Arthur Curry', 'Clint Barton'};
            for (Integer i = 0; i < hydraHcpNames.size(); i++) {
                String[] nameParts = hydraHcpNames[i].split(' ');
                String firstName = (nameParts.size() > 0) ? nameParts[0] : '';
                String lastName  = (nameParts.size() > 1) ? nameParts[nameParts.size() - 1] : firstName;
                String hcpSeedKey = 'HCP-' + lastName.toUpperCase();
                
                Account hcp = new Account(
                    FirstName    = firstName,
                    LastName     = lastName,
                    RecordTypeId = recordTypeIds.get('Professional'),
                    VEM_Region__c = 'West'
                );
                
                // Add random credential
                String[] credentials = new String[] {'MD', 'RN', 'NP', 'PA', 'PharmD'};
                Integer randomIndex = Math.mod(System.now().getTime().intValue() + i + 50, credentials.size());
                String randomCredential = credentials[randomIndex];
                hcp.put('Credential__c', randomCredential);
                hcpAccountsToCreate.add(hcp);
                hcpMap.put(hcpSeedKey, hcp);
            }

            // Insert HCPs
            if (!hcpAccountsToCreate.isEmpty()) {
                Database.SaveResult[] hcpResults = Database.insert(hcpAccountsToCreate, false);
                
            }

            // Build Org SeedKey -> Id and HCP SeedKey -> Id maps after insert
            Map<String, Id> orgSeedToId = new Map<String, Id>();
            orgSeedToId.put('ORG-SHIELD', [SELECT Id FROM Account WHERE Name = 'S.H.I.E.L.D' LIMIT 1].Id);
            orgSeedToId.put('ORG-DAILYPLANET', [SELECT Id FROM Account WHERE Name = 'Daily Planet' LIMIT 1].Id);
            orgSeedToId.put('ORG-WAYNE', [SELECT Id FROM Account WHERE Name = 'Wayne Enterprises' LIMIT 1].Id);
            orgSeedToId.put('ORG-STARK', [SELECT Id FROM Account WHERE Name = 'Stark Industries' LIMIT 1].Id);
            orgSeedToId.put('ORG-OSCORP', [SELECT Id FROM Account WHERE Name = 'Oscorp' LIMIT 1].Id);
            orgSeedToId.put('ORG-HYDRA', [SELECT Id FROM Account WHERE Name = 'Hydra' LIMIT 1].Id);
            Map<String, Id> hcpSeedToId = new Map<String, Id>();
            // We'll map by the seed keys we control to the inserted accounts' Ids
            for (String k : hcpMap.keySet()) {
                if (hcpMap.get(k).Id != null) hcpSeedToId.put(k, hcpMap.get(k).Id);
            }

            // Create Affiliations (idempotent by seed key)
            List<VEM_Affiliation__c> affsToCreate = new List<VEM_Affiliation__c>();
            Set<String> existingAffKeys = new Set<String>();
            for (VEM_Affiliation__c a : [SELECT Id, VEM_Seed_Key__c FROM VEM_Affiliation__c WHERE VEM_Seed_Key__c LIKE 'AFF-%']) {
                existingAffKeys.add(a.VEM_Seed_Key__c);
            }

            // Define deterministic affiliations for all HCPs
            // We'll create affiliations for all 18 HCPs with appropriate organization associations
            List<Map<String, String>> affDefs = new List<Map<String, String>>();
            
            // East Orgs - S.H.I.E.L.D (3 HCPs)
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-ROGERS-SHIELD',   'hcp' => 'HCP-ROGERS',   'org' => 'ORG-SHIELD' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-ROMANOFF-SHIELD', 'hcp' => 'HCP-ROMANOFF', 'org' => 'ORG-SHIELD' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-BANNER-SHIELD',   'hcp' => 'HCP-BANNER',   'org' => 'ORG-SHIELD' });
            
            // East Orgs - Daily Planet (3 HCPs)
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-KENT-DAILYPLANET',   'hcp' => 'HCP-KENT',   'org' => 'ORG-DAILYPLANET' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-DANVERS-DAILYPLANET', 'hcp' => 'HCP-DANVERS', 'org' => 'ORG-DAILYPLANET' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-ALLEN-DAILYPLANET',   'hcp' => 'HCP-ALLEN',   'org' => 'ORG-DAILYPLANET' });
            
            // East Orgs - Wayne Enterprises (3 HCPs)
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-WAYNE-WAYNE',     'hcp' => 'HCP-WAYNE',    'org' => 'ORG-WAYNE' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-PRINCE-WAYNE',    'hcp' => 'HCP-PRINCE',   'org' => 'ORG-WAYNE' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-KANE-WAYNE',      'hcp' => 'HCP-KANE',     'org' => 'ORG-WAYNE' });
            
            // West Orgs - Stark Industries (3 HCPs)
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-STARK-STARK',     'hcp' => 'HCP-STARK',    'org' => 'ORG-STARK' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-PARKER-STARK',    'hcp' => 'HCP-PARKER',   'org' => 'ORG-STARK' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-DANVERS-STARK',   'hcp' => 'HCP-DANVERS',  'org' => 'ORG-STARK' });
            
            // West Orgs - Oscorp (3 HCPs)
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-MAXIMOFF-OSCORP', 'hcp' => 'HCP-MAXIMOFF', 'org' => 'ORG-OSCORP' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-CHALLA-OSCORP',   'hcp' => 'HCP-CHALLA',   'org' => 'ORG-OSCORP' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-STRANGE-OSCORP',  'hcp' => 'HCP-STRANGE',  'org' => 'ORG-OSCORP' });
            
            // West Orgs - Hydra (3 HCPs)
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-RICHARDS-HYDRA',  'hcp' => 'HCP-RICHARDS', 'org' => 'ORG-HYDRA' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-CURRY-HYDRA',     'hcp' => 'HCP-CURRY',    'org' => 'ORG-HYDRA' });
            affDefs.add(new Map<String, String>{ 'key' => 'AFF-BARTON-HYDRA',    'hcp' => 'HCP-BARTON',   'org' => 'ORG-HYDRA' });

            for (Map<String, String> def : affDefs) {
                String key = def.get('key');
                if (existingAffKeys.contains(key)) {
                    affSkipped++;
                    continue;
                }
                Id hcpId = hcpSeedToId.get(def.get('hcp'));
                Id orgId = orgSeedToId.get(def.get('org'));
                if (hcpId == null || orgId == null) {
                    continue;
                }
                affsToCreate.add(new VEM_Affiliation__c(
                    VEM_Professional_Account__c = hcpId,
                    VEM_Organization_Account__c = orgId,
                    VEM_From_Date__c = Date.today(),
                    VEM_To_Date__c = Date.today().addYears(1),
                    VEM_Seed_Key__c = key
                ));
            }

            if (!affsToCreate.isEmpty()) {
                Database.SaveResult[] affResults = Database.insert(affsToCreate, false);
               
            }

            // ADDRESS SEEDING (Integrated)
            // Build existing Address map by seed key to ensure idempotency
            Map<String, VEM_Address__c> existingAddresses = new Map<String, VEM_Address__c>();
            for (VEM_Address__c a : [SELECT Id, VEM_Seed_Key__c, Account__c, VEM_Address_Line_1__c, VEM_City__c, VEM_State__c, VEM_Country__c, VEM_Zip_Code__c
                                      FROM VEM_Address__c
                                      WHERE VEM_Seed_Key__c != null]) {
                existingAddresses.put(a.VEM_Seed_Key__c, a);
            }

            // 1) Create Org Addresses
            List<VEM_Address__c> orgAddrToInsert = new List<VEM_Address__c>();
            // Need fresh orgs with Region and Id (by Organization record type)
            List<Account> allSeedOrgs = [SELECT Id, Name, BillingCity, BillingState, BillingCountry FROM Account WHERE RecordType.Name = 'Organization'];
            for (Account org : allSeedOrgs) {
                // map by name to deterministic "seed keys"
                String orgKey = 'ORG-' + org.Name.replaceAll('\\s','').toUpperCase().substring(0, Math.min( org.Name.replaceAll('\\s','').length(), 10 ));
                String addrSeed = 'ADDR-ORG-' + orgKey;
                if (existingAddresses.containsKey(addrSeed)) { orgAddrSkipped++; continue; }

                String line1, city, state, country, zipc;
                // Derive region from BillingState
                Boolean isWest = (org.BillingState == 'CA');
                if (isWest) {
                    line1 = '500 West Innovation Drive'; city = 'San Francisco'; state = 'CA'; country = 'USA'; zipc = '94105';
                } else {
                    line1 = '100 East Medical Plaza'; city = 'New York'; state = 'NY'; country = 'USA'; zipc = '10001';
                }

                VEM_Address__c a = new VEM_Address__c(
                    Account__c = org.Id,
                    VEM_Address_Line_1__c = line1,
                    VEM_City__c = city,
                    VEM_State__c = state,
                    VEM_Country__c = country,
                    VEM_Zip_Code__c = zipc,
                    VEM_Seed_Key__c = addrSeed
                );
                a.VEM_Address_Line_2__c = '';
                orgAddrToInsert.add(a);
            }

            if (!orgAddrToInsert.isEmpty()) {
                Database.SaveResult[] res = Database.insert(orgAddrToInsert, false);
                
            }

            // Build Org Id -> Address for copy to HCPs
            Map<Id, VEM_Address__c> orgIdToAddress = new Map<Id, VEM_Address__c>();
            if (!orgSeedToId.isEmpty()) {
                for (VEM_Address__c a : [SELECT Id, Account__c, VEM_Address_Line_1__c, VEM_City__c, VEM_State__c, VEM_Country__c, VEM_Zip_Code__c, VEM_Address_Line_2__c
                                          FROM VEM_Address__c WHERE Account__c IN :orgSeedToId.values()]) {
                    orgIdToAddress.put(a.Account__c, a);
                }
            }

            // 2) Create HCP Addresses derived from their primary org affiliation
            List<VEM_Address__c> hcpAddrToInsert = new List<VEM_Address__c>();
            // Get affiliations linking HCP to Org
            List<VEM_Affiliation__c> affs = [SELECT Id, VEM_Professional_Account__c, VEM_Organization_Account__c
                                             FROM VEM_Affiliation__c
                                             WHERE VEM_Professional_Account__c != null AND VEM_Organization_Account__c != null];

            // Build HCP Id -> seed key map
            Map<Id, String> hcpIdToSeed = new Map<Id, String>();
            for (String seedKey : hcpSeedToId.keySet()) {
                hcpIdToSeed.put(hcpSeedToId.get(seedKey), seedKey);
            }
            
            // Build Org Id -> seed key map
            Map<Id, String> orgIdToSeed = new Map<Id, String>();
            for (String seedKey : orgSeedToId.keySet()) {
                orgIdToSeed.put(orgSeedToId.get(seedKey), seedKey);
            }

            for (VEM_Affiliation__c a : affs) {
                String hcpSeed = hcpIdToSeed.get(a.VEM_Professional_Account__c);
                if (hcpSeed == null || hcpSeed == '') continue;
                
                String orgSeed = orgIdToSeed.get(a.VEM_Organization_Account__c);
                if (orgSeed == null || orgSeed == '') continue;

                // Make seed key unique by including organization
                String addrSeed = 'ADDR-HCP-' + hcpSeed + '-' + orgSeed;
                if (existingAddresses.containsKey(addrSeed)) { hcpAddrSkipped++; continue; }

                VEM_Address__c orgAddr = orgIdToAddress.get(a.VEM_Organization_Account__c);
                if (orgAddr == null) continue;

                VEM_Address__c hcpAddr = new VEM_Address__c(
                    Account__c = a.VEM_Professional_Account__c,
                    VEM_Address_Line_1__c = orgAddr.VEM_Address_Line_1__c,
                    VEM_City__c = orgAddr.VEM_City__c,
                    VEM_State__c = orgAddr.VEM_State__c,
                    VEM_Country__c = orgAddr.VEM_Country__c,
                    VEM_Zip_Code__c = orgAddr.VEM_Zip_Code__c,
                    VEM_Seed_Key__c = addrSeed
                );
                hcpAddr.VEM_Address_Line_2__c = orgAddr.VEM_Address_Line_2__c;
                hcpAddrToInsert.add(hcpAddr);
            }

            if (!hcpAddrToInsert.isEmpty()) {
                Database.SaveResult[] res2 = Database.insert(hcpAddrToInsert, false);
            }

           
            return 'seeded accounts and affiliations';
        
    }
    
   
    
    /**
     * Method to create Address records for Organization Accounts and HCP Person Accounts
     * @return String Summary of created/skipped records
     */
    @AuraEnabled
    public static String seedAddresses() {
       
            // Track counts
            Integer orgAddrCreated = 0;
            Integer orgAddrSkipped = 0;
            Integer hcpAddrCreated = 0;
            Integer hcpAddrSkipped = 0;
            
            // Maps to store existing records by seed key
            Map<String, VEM_Address__c> existingAddresses = new Map<String, VEM_Address__c>();
            
            // Get existing addresses by seed key
            List<VEM_Address__c> existingAddressRecords = [SELECT Id, VEM_Seed_Key__c FROM VEM_Address__c WHERE VEM_Seed_Key__c != null];
            for (VEM_Address__c addr : existingAddressRecords) {
                existingAddresses.put(addr.VEM_Seed_Key__c, addr);
            }
            
            // Get existing organization accounts (fallback to Id-based mapping since custom fields may not exist)
            Map<String, Account> existingOrgs = new Map<String, Account>();
            List<Account> existingOrgRecords = [SELECT Id, Name, BillingCity, BillingState, BillingCountry FROM Account WHERE Type = 'Organization'];
            for (Account acc : existingOrgRecords) {
                existingOrgs.put(String.valueOf(acc.Id), acc);
            }
            
            // Get existing person accounts (fallback to Id-based mapping since custom fields may not exist)
            Map<String, Account> existingHcps = new Map<String, Account>();
            List<Account> existingHcpRecords = [SELECT Id FROM Account WHERE Type = 'Professional'];
            for (Account acc : existingHcpRecords) {
                existingHcps.put(String.valueOf(acc.Id), acc);
            }
            
            // Get existing affiliations by seed key
            Map<String, VEM_Affiliation__c> existingAffiliations = new Map<String, VEM_Affiliation__c>();
            List<VEM_Affiliation__c> existingAffiliationRecords = [SELECT Id, VEM_Seed_Key__c, VEM_Professional_Account__c, VEM_Organization_Account__c FROM VEM_Affiliation__c WHERE VEM_Seed_Key__c != null];
            for (VEM_Affiliation__c aff : existingAffiliationRecords) {
                existingAffiliations.put(aff.VEM_Seed_Key__c, aff);
            }
            
            // Get existing organization addresses by organization account ID
            Map<Id, VEM_Address__c> orgAddressMap = new Map<Id, VEM_Address__c>();
            List<VEM_Address__c> existingOrgAddresses = [SELECT Id, Account__c, VEM_Seed_Key__c FROM VEM_Address__c WHERE Account__c != null];
            for (VEM_Address__c addr : existingOrgAddresses) {
                orgAddressMap.put(addr.Account__c, addr);
            }
            
            // 1. Create Organization Addresses
            List<VEM_Address__c> orgAddressesToCreate = new List<VEM_Address__c>();
            
            // Process existing organizations to create addresses
            for (Account org : existingOrgRecords) {
                // Derive a deterministic key from Name to simulate seed key
                String orgSeedKey = 'ORG-' + org.Name.replaceAll('\\s','').toUpperCase().substring(0, Math.min(org.Name.replaceAll('\\s','').length(), 10));
                String addrSeedKey = 'ADDR-ORG-' + orgSeedKey;
                
                // Skip if address already exists
                if (existingAddresses.containsKey(addrSeedKey)) {
                    orgAddrSkipped++;
                    continue;
                }
                
                // Create address based on region
                String addrLine1 = '';
                String city = '';
                String state = '';
                String country = '';
                String zipCode = '';
                
                // Derive region from BillingState
                Boolean isWest = (org.BillingState == 'CA');
                if (isWest) {
                    addrLine1 = '500 West Innovation Drive';
                    city = 'San Francisco';
                    state = 'CA';
                    country = 'USA';
                    zipCode = '94105';
                } else {
                    addrLine1 = '100 East Medical Plaza';
                    city = 'New York';
                    state = 'NY';
                    country = 'USA';
                    zipCode = '10001';
                }
                
                // Create the address record
                VEM_Address__c addr = new VEM_Address__c(
                    Account__c = org.Id,
                    VEM_Address_Line_1__c = addrLine1,
                    VEM_City__c = city,
                    VEM_State__c = state,
                    VEM_Country__c = country,
                    VEM_Zip_Code__c = zipCode,
                    VEM_Seed_Key__c = addrSeedKey
                );
                
                // Set optional fields
                addr.VEM_Address_Line_2__c = ''; // Empty as optional
                
                orgAddressesToCreate.add(addr);
            }
            
            // Insert organization addresses
            if (!orgAddressesToCreate.isEmpty()) {
                Database.SaveResult[] orgAddrResults = Database.insert(orgAddressesToCreate, false);
                
            }
            
            // 2. Create HCP Addresses using Organization Address data
            List<VEM_Address__c> hcpAddressesToCreate = new List<VEM_Address__c>();
            
            // Query affiliations to link HCPs to Organizations
            List<VEM_Affiliation__c> affiliations = [SELECT Id, VEM_Seed_Key__c, VEM_Professional_Account__c, VEM_Organization_Account__c 
                                                     FROM VEM_Affiliation__c 
                                                     WHERE VEM_Seed_Key__c != null 
                                                     AND VEM_Professional_Account__c != null 
                                                     AND VEM_Organization_Account__c != null];
            
            // Process each affiliation to create HCP addresses
            for (VEM_Affiliation__c aff : affiliations) {
                String hcpSeedKey = '';
                Account hcpAccount = existingHcps.get(aff.VEM_Professional_Account__c);
                Account orgAccount = existingOrgs.get(aff.VEM_Organization_Account__c);
                
                // Derive the HCP seed key deterministically since custom field may not exist
                if (hcpAccount != null) {
                    String nameKey = (hcpAccount.FirstName != null ? hcpAccount.FirstName : '') + (hcpAccount.LastName != null ? hcpAccount.LastName : '');
                    nameKey = nameKey.replaceAll('\\s','').toUpperCase();
                    hcpSeedKey = 'HCP-' + (nameKey == null || nameKey == '' ? String.valueOf(hcpAccount.Id).left(6) : nameKey.substring(0, Math.min(nameKey.length(), 10)));
                }
                
                if (hcpSeedKey == '' || hcpAccount == null || orgAccount == null) {
                    continue;
                }
                
                // Derive the Org seed key for uniqueness
                String orgSeedKey = '';
                if (orgAccount != null) {
                    String orgNameKey = (orgAccount.Name != null ? orgAccount.Name : '');
                    orgNameKey = orgNameKey.replaceAll('\\s','').toUpperCase();
                    orgSeedKey = 'ORG-' + (orgNameKey == null || orgNameKey == '' ? String.valueOf(orgAccount.Id).left(6) : orgNameKey.substring(0, Math.min(orgNameKey.length(), 15)));
                }
                
                // Make seed key unique by including organization
                String hcpAddrSeedKey = 'ADDR-HCP-' + hcpSeedKey + '-' + orgSeedKey;
                
                // Skip if address already exists
                if (existingAddresses.containsKey(hcpAddrSeedKey)) {
                    hcpAddrSkipped++;
                    continue;
                }
                
                // Get the organization's address data
                VEM_Address__c orgAddress = orgAddressMap.get(orgAccount.Id);
                if (orgAddress == null) {
                    // If no organization address exists, skip creating HCP address
                    continue;
                }
                
                // Create HCP address with the same data as the organization
                VEM_Address__c hcpAddr = new VEM_Address__c(
                    Account__c = hcpAccount.Id,
                    VEM_Address_Line_1__c = orgAddress.VEM_Address_Line_1__c,
                    VEM_City__c = orgAddress.VEM_City__c,
                    VEM_State__c = orgAddress.VEM_State__c,
                    VEM_Country__c = orgAddress.VEM_Country__c,
                    VEM_Zip_Code__c = orgAddress.VEM_Zip_Code__c,
                    VEM_Seed_Key__c = hcpAddrSeedKey
                );
                
                // Copy optional fields
                hcpAddr.VEM_Address_Line_2__c = orgAddress.VEM_Address_Line_2__c;
                
                hcpAddressesToCreate.add(hcpAddr);
            }
            
            // Insert HCP addresses
            if (!hcpAddressesToCreate.isEmpty()) {
                Database.SaveResult[] hcpAddrResults = Database.insert(hcpAddressesToCreate, false);
            }
            
            return 'Created addresses ' ;
       
    }
    
    /**
     * Method to delete Accounts and Affiliations created by the seedAccountsAndAffiliations method
     * @return String Success message or error details
     */
    @AuraEnabled
    public static String deleteAccountsAndAffiliations() {
       
            // Log the start of deletion process
            System.debug('Starting deletion of Accounts and Affiliations...');
            
            // Collect detailed delete errors so they can be surfaced in the UI
            List<String> deleteErrors = new List<String>();
            
            // Delete addresses first (in reverse dependency order to avoid foreign key constraint issues)
            List<VEM_Address__c> addressesToDelete = [SELECT Id FROM VEM_Address__c WHERE VEM_Seed_Key__c LIKE 'ADDR-%'];
            System.debug('Found ' + addressesToDelete.size() + ' addresses to delete');
            if (!addressesToDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(addressesToDelete, false);
                
            }
            
            // Delete affiliations first (in reverse dependency order to avoid foreign key constraint issues)
            List<VEM_Affiliation__c> affiliationsToDelete = [SELECT Id FROM VEM_Affiliation__c WHERE VEM_Seed_Key__c LIKE 'AFF-%'];
            System.debug('Found ' + affiliationsToDelete.size() + ' affiliations to delete');
            if (!affiliationsToDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(affiliationsToDelete, false);
                for (Database.DeleteResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('Error deleting affiliation: ' + result.getErrors()[0].getMessage());
                        if (result.getErrors() != null && !result.getErrors().isEmpty()) {
                            deleteErrors.add('Affiliation delete failed: ' + result.getErrors()[0].getMessage());
                        } else {
                            deleteErrors.add('Affiliation delete failed with unknown error.');
                        }
                    }
                }
            }
            
            // Delete Professional Person Accounts
            List<Account> profAccountsToDelete = [SELECT Id FROM Account WHERE RecordType.Name = 'Professional'];
            System.debug('Found ' + profAccountsToDelete.size() + ' professional accounts to delete');
            if (!profAccountsToDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(profAccountsToDelete, false);
                
            }
            
            // Delete Organization Accounts
            List<Account> orgAccountsToDelete = [SELECT Id FROM Account WHERE RecordType.Name = 'Organization'];
            System.debug('Found ' + orgAccountsToDelete.size() + ' organization accounts to delete');
            if (!orgAccountsToDelete.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(orgAccountsToDelete, false);
                
            }

            List<Account> accountsToDelete = [SELECT Id FROM Account];
            // First, query and delete all child records (Cases, Opportunities, Entitlements) associated with the accounts
            
            if (!accountsToDelete.isEmpty()) {
                Set<Id> accountIds = new Set<Id>();
                for (Account acc : accountsToDelete) {
                    accountIds.add(acc.Id);
                }

                // 1. Delete Cases
                List<Case> casesToDelete = [SELECT Id FROM Case WHERE AccountId IN :accountIds];
                if (!casesToDelete.isEmpty()) {
                    Database.DeleteResult[] results = Database.delete(casesToDelete, false);
                    
                }

                // 2. Delete Opportunities
                List<Opportunity> oppsToDelete = [SELECT Id FROM Opportunity WHERE AccountId IN :accountIds];
                if (!oppsToDelete.isEmpty()) {
                    Database.DeleteResult[] results = Database.delete(oppsToDelete, false);
                    
                } 

                // 3. Delete Entitlements (if object exists in org)
                // Try/catch block in case Entitlement is not enabled in org
                try {
                    List<Entitlement> entsToDelete = [SELECT Id FROM Entitlement WHERE AccountId IN :accountIds];
                    if (!entsToDelete.isEmpty()) {
                        Database.DeleteResult[] results = Database.delete(entsToDelete, false);
                        
                    }
                } catch (Exception entEx) {
                    System.debug('Entitlement deletion skipped/not enabled. ' + entEx.getMessage());
                }

                // Now delete the Accounts themselves
                Database.DeleteResult[] accDelResults = Database.delete(accountsToDelete, false);
               
            }
            
         
            return 'ran delete accounts and affiliations';
       
        
    }
    
    /**
     * Method to create comprehensive Events data
     * Creates 20 past events and 20 future events with consultants, attendees, and expenses
     * @return String Summary of created records or error details
     */
    @AuraEnabled
    public static String seedEventsData() {
        
            Integer eventCreated = 0;
            Integer eventConsultantCreated = 0;
            Integer attendeeCreated = 0;
            Integer expenseHeaderCreated = 0;
            Integer expenseLineItemCreated = 0;
            List<String> errorMessages = new List<String>();
            
            // Get Sales Rep users by role
            List<User> eastReps = [
                SELECT Id, Name 
                FROM User 
                WHERE UserRole.Name = 'VEM_Sales_East_Rep' 
                AND IsActive = true 
                LIMIT 1
            ];
            List<User> westReps = [
                SELECT Id, Name 
                FROM User 
                WHERE UserRole.Name = 'VEM_Sales_West_Rep' 
                AND IsActive = true 
                LIMIT 1
            ];
            
            if (eastReps.isEmpty() || westReps.isEmpty()) {
                return 'Error: Sales Rep users not found. Please create users with roles "SALES EAST Rep" and "Sales West Rep" first.';
            }
            
            User eastRep = eastReps[0];
            User westRep = westReps[0];
            
            // Get Products
            List<VEM_Product__c> products = [
                SELECT Id, VEM_Name__c 
                FROM VEM_Product__c 
                WHERE VEM_Name__c IN ('OncoBlaster X', 'NeuroNova Core')
            ];
            
            Map<String, Id> productMap = new Map<String, Id>();
            for (VEM_Product__c p : products) {
                productMap.put(p.VEM_Name__c, p.Id);
            }
            
            if (productMap.isEmpty()) {
                return 'Error: Products not found. Please create OncoBlaster X and NeuroNova Core products first.';
            }
            
            // Get Record Types for Events
            Map<String, Id> eventRecordTypes = new Map<String, Id>();
            for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'VEM_Event__c']) {
                eventRecordTypes.put(rt.Name, rt.Id);
            }
            
            // Get Consultants by region
            Set<String> eastFirstNames = new Set<String>{'Steve', 'Natasha', 'Bruce', 'Clark', 'Kara', 'Barry', 'Diana', 'Kate'};
            List<VEM_Consultant__c> eastConsultants = [
                SELECT Id, VEM_Professional_Account__c, VEM_Professional_Account__r.FirstName, VEM_Professional_Account__r.LastName
                FROM VEM_Consultant__c
                WHERE VEM_Professional_Account__r.RecordType.Name = 'Professional'
                AND VEM_Professional_Account__r.FirstName IN :eastFirstNames
                LIMIT 10
            ];
            
            Set<String> westFirstNames = new Set<String>{'Tony', 'Peter', 'Carol', 'Wanda', 'Stephen', 'Reed', 'Arthur', 'Clint'};
            List<VEM_Consultant__c> westConsultants = [
                SELECT Id, VEM_Professional_Account__c, VEM_Professional_Account__r.FirstName, VEM_Professional_Account__r.LastName
                FROM VEM_Consultant__c
                WHERE VEM_Professional_Account__r.RecordType.Name = 'Professional'
                AND (VEM_Professional_Account__r.FirstName IN :westFirstNames OR VEM_Professional_Account__r.LastName LIKE '%Challa%')
                LIMIT 10
            ];
            
            // Get Professional Accounts for attendees
            List<Account> attendeeAccounts = [
                SELECT Id 
                FROM Account 
                WHERE RecordType.Name = 'Professional'
                LIMIT 50
            ];
            
            // Event topics by product
            Map<String, String> productTopics = new Map<String, String>{
                'OncoBlaster X' => 'ALL & AML Treatment Protocols (≥12 years)',
                'NeuroNova Core' => 'ARRMS Management with Active Lesions'
            };
            
            // Past event statuses
            List<String> pastStatuses = new List<String>{'Completed', 'Financially Closed'};
            // Future event statuses
            List<String> futureStatuses = new List<String>{'Draft', 'In-Progress', 'Setup Complete'};
            
            // Event types
            List<String> eventTypes = new List<String>{'Live', 'Web'};
            
            List<VEM_Event__c> eventsToCreate = new List<VEM_Event__c>();
            List<VEM_Event_Consultant__c> eventConsultantsToCreate = new List<VEM_Event_Consultant__c>();
            List<VEM_Attendee__c> attendeesToCreate = new List<VEM_Attendee__c>();
            List<VEM_Expense_Header__c> expenseHeadersToCreate = new List<VEM_Expense_Header__c>();
            List<VEM_Expense_Line_Item__c> expenseLineItemsToCreate = new List<VEM_Expense_Line_Item__c>();
            
            // Date ranges
            Date futureStart = Date.newInstance(2025, 4, 1);
            Date futureEnd = Date.newInstance(2026, 3, 31);
            Date today = Date.today();
            Date pastStart = today.addDays(-365); // 1 year ago
            
            // Create 20 past events
            for (Integer i = 0; i < 20; i++) {
                Boolean isEast = (Math.mod(i, 2) == 0);
                User rep = isEast ? eastRep : westRep;
                String region = isEast ? 'East' : 'West';
                List<VEM_Consultant__c> consultants = isEast ? eastConsultants : westConsultants;
                
                if (consultants.isEmpty()) continue;
                
                VEM_Consultant__c consultant = consultants[Math.mod(i, consultants.size())];
                String consultantName = consultant.VEM_Professional_Account__r.FirstName + ' ' + consultant.VEM_Professional_Account__r.LastName;
                
                // Choose product and record type
                String productName = (Math.mod(i, 2) == 0) ? 'OncoBlaster X' : 'NeuroNova Core';
                String recordTypeName = productName + ' Speaker Program';
                Id recordTypeId = eventRecordTypes.get(recordTypeName);
                if (recordTypeId == null) continue;
                
                // Generate past date
                Integer daysAgo = 30 + (Math.mod(i * 17, 335)); // Spread over past year
                DateTime eventDate = DateTime.newInstance(pastStart.addDays(daysAgo), Time.newInstance(14, 0, 0, 0));
                
                // Status
                String status = pastStatuses[Math.mod(i, pastStatuses.size())];
                String eventType = eventTypes[Math.mod(i, eventTypes.size())];
                
                // Title: Product-Date-Event Consultant Name
                String title = productName + '-' + eventDate.format('MM/dd/yyyy') + '-' + consultantName;
                
                // Get product ID based on product name
                Id productId = productMap.get(productName);
                
                VEM_Event__c event = new VEM_Event__c(
                    VEM_Title__c = title,
                    VEM_Event_Type__c = eventType,
                    VEM_Status__c = status,
                    VEM_Event_Date__c = eventDate,
                    VEM_Event_Topic__c = productTopics.get(productName),
                    VEM_Region__c = region,
                    RecordTypeId = recordTypeId,
                    OwnerId = rep.Id,
                    VEM_Product__c = productId
                );
                eventsToCreate.add(event);
            }
            
            // Insert past events
            if (!eventsToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(eventsToCreate, false);
                List<VEM_Event__c> insertedEvents = new List<VEM_Event__c>();
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        eventCreated++;
                        insertedEvents.add(eventsToCreate[i]);
                    } 
                }
                
                // Create event consultants, attendees, and expenses for past events
                for (Integer i = 0; i < insertedEvents.size(); i++) {
                    VEM_Event__c event = insertedEvents[i];
                    Boolean isEast = (Math.mod(i, 2) == 0);
                    List<VEM_Consultant__c> consultants = isEast ? eastConsultants : westConsultants;
                    if (consultants.isEmpty()) continue;
                    
                    VEM_Consultant__c consultant = consultants[Math.mod(i, consultants.size())];
                    
                    // Primary event consultant - Attended
                    VEM_Event_Consultant__c eventConsultant = new VEM_Event_Consultant__c(
                        VEM_Event__c = event.Id,
                        VEM_Consultant__c = consultant.Id,
                        VEM_Speaker_Status__c = 'Attended'
                    );
                    eventConsultantsToCreate.add(eventConsultant);
                    
                    // Some events get additional declined consultant
                    if (Math.mod(i, 3) == 0 && consultants.size() > 1) {
                        VEM_Consultant__c declinedConsultant = consultants[Math.mod(i + 1, consultants.size())];
                        VEM_Event_Consultant__c declinedEventConsultant = new VEM_Event_Consultant__c(
                            VEM_Event__c = event.Id,
                            VEM_Consultant__c = declinedConsultant.Id,
                            VEM_Speaker_Status__c = 'Declined'
                        );
                        eventConsultantsToCreate.add(declinedEventConsultant);
                    }
                    
                    // Create 4-5 attendees
                    Integer numAttendees = 4 + Math.mod(i, 2); // 4 or 5
                    for (Integer j = 0; j < numAttendees && j < attendeeAccounts.size(); j++) {
                        Account attendeeAccount = attendeeAccounts[Math.mod(i * 5 + j, attendeeAccounts.size())];
                        String attendeeStatus = (j < numAttendees - 1) ? 'Attended' : (Math.mod(i, 5) == 0 ? 'No-Show' : 'Attended');
                        Boolean mealTaken = (attendeeStatus == 'Attended' && Math.mod(j, 2) == 0);
                        
                        VEM_Attendee__c attendee = new VEM_Attendee__c(
                            VEM_Professional_Account__c = attendeeAccount.Id,
                            VEM_Event__c = event.Id,
                            VEM_Status__c = attendeeStatus,
                            VEM_Meal_Taken__c = mealTaken
                        );
                        attendeesToCreate.add(attendee);
                    }
                    
                    // Create expenses for Completed/Financially Closed events
                    if (event.VEM_Status__c == 'Completed' || event.VEM_Status__c == 'Financially Closed') {
                        // Individual expense header with Honorarium
                        VEM_Expense_Header__c individualHeader = new VEM_Expense_Header__c(
                            VEM_Event__c = event.Id,
                            VEM_Type__c = 'Individual',
                            VEM_Account__c = consultant.VEM_Professional_Account__c,
                            VEM_Consultant__c = consultant.Id,
                            VEM_Currency__c = 'USD',
                            VEM_Submission_Date__c = event.VEM_Event_Date__c.date().addDays(7)
                        );
                        expenseHeadersToCreate.add(individualHeader);
                        
                        // Some events get Travel/Accommodation
                        if (Math.mod(i, 2) == 0) {
                            VEM_Expense_Header__c travelHeader = new VEM_Expense_Header__c(
                                VEM_Event__c = event.Id,
                                VEM_Type__c = 'Individual',
                                VEM_Account__c = consultant.VEM_Professional_Account__c,
                                VEM_Consultant__c = consultant.Id,
                                VEM_Currency__c = 'USD',
                                VEM_Submission_Date__c = event.VEM_Event_Date__c.date().addDays(7)
                            );
                            expenseHeadersToCreate.add(travelHeader);
                        }
                        
                        // Meeting expense header for all past events
                        VEM_Expense_Header__c meetingHeader = new VEM_Expense_Header__c(
                            VEM_Event__c = event.Id,
                            VEM_Type__c = 'Meeting',
                            VEM_Currency__c = 'USD',
                            VEM_Submission_Date__c = event.VEM_Event_Date__c.date().addDays(7)
                        );
                        expenseHeadersToCreate.add(meetingHeader);
                    }
                }
            }
            
            // Create 20 future events
            List<VEM_Event__c> futureEventsToCreate = new List<VEM_Event__c>();
            for (Integer i = 0; i < 20; i++) {
                Boolean isEast = (Math.mod(i, 2) == 0);
                User rep = isEast ? eastRep : westRep;
                String region = isEast ? 'East' : 'West';
                List<VEM_Consultant__c> consultants = isEast ? eastConsultants : westConsultants;
                
                if (consultants.isEmpty()) continue;
                
                VEM_Consultant__c consultant = consultants[Math.mod(i, consultants.size())];
                String consultantName = consultant.VEM_Professional_Account__r.FirstName + ' ' + consultant.VEM_Professional_Account__r.LastName;
                
                // Choose product and record type
                String productName = (Math.mod(i, 2) == 0) ? 'OncoBlaster X' : 'NeuroNova Core';
                String recordTypeName = productName + ' Speaker Program';
                Id recordTypeId = eventRecordTypes.get(recordTypeName);
                if (recordTypeId == null) continue;
                
                // Generate future date between April 1, 2025 to March 31, 2026
                Integer daysFromStart = Math.mod(i * 19, 365);
                DateTime eventDate = DateTime.newInstance(futureStart.addDays(daysFromStart), Time.newInstance(14, 0, 0, 0));
                
                // Status
                String status = futureStatuses[Math.mod(i, futureStatuses.size())];
                String eventType = eventTypes[Math.mod(i, eventTypes.size())];
                
                // Title: Product-Date-Event Consultant Name
                String title = productName + '-' + eventDate.format('MM/dd/yyyy') + '-' + consultantName;
                
                // Get product ID based on product name
                Id productId = productMap.get(productName);
                
                VEM_Event__c event = new VEM_Event__c(
                    VEM_Title__c = title,
                    VEM_Event_Type__c = eventType,
                    VEM_Status__c = status,
                    VEM_Event_Date__c = eventDate,
                    VEM_Event_Topic__c = productTopics.get(productName),
                    VEM_Region__c = region,
                    RecordTypeId = recordTypeId,
                    OwnerId = rep.Id,
                    VEM_Product__c = productId
                );
                futureEventsToCreate.add(event);
            }
            
            // Insert future events
            if (!futureEventsToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(futureEventsToCreate, false);
                List<VEM_Event__c> insertedFutureEvents = new List<VEM_Event__c>();
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        eventCreated++;
                        insertedFutureEvents.add(futureEventsToCreate[i]);
                    } 
                }
                
                // Create event consultants and attendees for future events
                for (Integer i = 0; i < insertedFutureEvents.size(); i++) {
                    VEM_Event__c event = insertedFutureEvents[i];
                    Boolean isEast = (Math.mod(i, 2) == 0);
                    List<VEM_Consultant__c> consultants = isEast ? eastConsultants : westConsultants;
                    if (consultants.isEmpty()) continue;
                    
                    VEM_Consultant__c consultant = consultants[Math.mod(i, consultants.size())];
                    
                    // Event consultant - Invited or Accepted
                    String consultantStatus = (Math.mod(i, 2) == 0) ? 'Invited' : 'Accepted';
                    VEM_Event_Consultant__c eventConsultant = new VEM_Event_Consultant__c(
                        VEM_Event__c = event.Id,
                        VEM_Consultant__c = consultant.Id,
                        VEM_Speaker_Status__c = consultantStatus
                    );
                    eventConsultantsToCreate.add(eventConsultant);
                    
                    // Create 4-5 attendees
                    Integer numAttendees = 4 + Math.mod(i, 2); // 4 or 5
                    for (Integer j = 0; j < numAttendees && j < attendeeAccounts.size(); j++) {
                        Account attendeeAccount = attendeeAccounts[Math.mod(i * 5 + j, attendeeAccounts.size())];
                        String attendeeStatus = (Math.mod(j, 2) == 0) ? 'Invited' : 'Accepted';
                        VEM_Attendee__c attendee = new VEM_Attendee__c(
                            VEM_Professional_Account__c = attendeeAccount.Id,
                            VEM_Event__c = event.Id,
                            VEM_Status__c = attendeeStatus
                        );
                        attendeesToCreate.add(attendee);
                    }
                }
            }
            
            // Insert event consultants
            if (!eventConsultantsToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(eventConsultantsToCreate, false);
                for (Database.SaveResult result : results) {
                    if (result.isSuccess()) {
                        eventConsultantCreated++;
                    } 
                }
            }
            
            // Insert attendees
            if (!attendeesToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(attendeesToCreate, false);
                for (Database.SaveResult result : results) {
                    if (result.isSuccess()) {
                        attendeeCreated++;
                    } 
                }
            }
            
            // Insert expense headers
            if (!expenseHeadersToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(expenseHeadersToCreate, false);
                List<VEM_Expense_Header__c> insertedHeaders = new List<VEM_Expense_Header__c>();
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        expenseHeaderCreated++;
                        insertedHeaders.add(expenseHeadersToCreate[i]);
                    } 
                }
                
                // Create expense line items
                for (VEM_Expense_Header__c header : insertedHeaders) {
                    if (header.VEM_Type__c == 'Individual') {
                        // Honorarium line item
                        VEM_Expense_Line_Item__c honorarium = new VEM_Expense_Line_Item__c(
                            VEM_Expense_Header__c = header.Id,
                            VEM_Type__c = 'Honorarium',
                            VEM_Amount__c = 750.00 + (Math.mod(Crypto.getRandomInteger(), 250)),
                            VEM_Currency__c = 'USD',
                            VEM_Description__c = 'Speaker honorarium',
                            VEM_Date__c = header.VEM_Submission_Date__c
                        );
                        expenseLineItemsToCreate.add(honorarium);
                        
                        // Some get Travel or Accommodation
                        if (Math.mod(expenseLineItemsToCreate.size(), 3) == 0) {
                            String travelType = (Math.mod(expenseLineItemsToCreate.size(), 2) == 0) ? 'Travel' : 'Accommodation';
                            VEM_Expense_Line_Item__c travel = new VEM_Expense_Line_Item__c(
                                VEM_Expense_Header__c = header.Id,
                                VEM_Type__c = travelType,
                                VEM_Amount__c = 200.00 + (Math.mod(Crypto.getRandomInteger(), 300)),
                                VEM_Currency__c = 'USD',
                                VEM_Description__c = travelType + ' expenses',
                                VEM_Date__c = header.VEM_Submission_Date__c
                            );
                            expenseLineItemsToCreate.add(travel);
                        }
                    } else if (header.VEM_Type__c == 'Meeting') {
                        // Meal line item
                        VEM_Expense_Line_Item__c meal = new VEM_Expense_Line_Item__c(
                            VEM_Expense_Header__c = header.Id,
                            VEM_Type__c = 'Meal',
                            VEM_Amount__c = 50.00 + (Math.mod(Crypto.getRandomInteger(), 100)),
                            VEM_Currency__c = 'USD',
                            VEM_Description__c = 'Meeting meal expenses',
                            VEM_Date__c = header.VEM_Submission_Date__c
                        );
                        expenseLineItemsToCreate.add(meal);
                    }
                }
                
                // Insert expense line items
                if (!expenseLineItemsToCreate.isEmpty()) {
                    results = Database.insert(expenseLineItemsToCreate, false);
                    
                }
            }
            
            
            return 'ran events data seeding';
       
    }
    
    /**
     * Method to delete all Events data (expenses, attendees, event consultants, events)
     * @return String Success message or error details
     */
    @AuraEnabled
    public static String deleteEventsData() {
        try {
            Integer expenseLineItemDeleted = 0;
            Integer expenseHeaderDeleted = 0;
            Integer attendeeDeleted = 0;
            Integer eventConsultantDeleted = 0;
            Integer eventDeleted = 0;
            List<String> deleteErrors = new List<String>();
            
            // Delete in reverse dependency order
            
            // 1. Delete Expense Line Items
            List<VEM_Expense_Line_Item__c> expenseLineItems = [SELECT Id FROM VEM_Expense_Line_Item__c];
            if (!expenseLineItems.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(expenseLineItems, false);
                for (Database.DeleteResult result : results) {
                    if (result.isSuccess()) {
                        expenseLineItemDeleted++;
                    } else {
                        if (result.getErrors() != null && !result.getErrors().isEmpty()) {
                            deleteErrors.add('Expense Line Item delete failed: ' + result.getErrors()[0].getMessage());
                        }
                    }
                }
            }
            
            // 2. Delete Expense Headers
            List<VEM_Expense_Header__c> expenseHeaders = [SELECT Id FROM VEM_Expense_Header__c];
            if (!expenseHeaders.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(expenseHeaders, false);
                for (Database.DeleteResult result : results) {
                    if (result.isSuccess()) {
                        expenseHeaderDeleted++;
                    } else {
                        if (result.getErrors() != null && !result.getErrors().isEmpty()) {
                            deleteErrors.add('Expense Header delete failed: ' + result.getErrors()[0].getMessage());
                        }
                    }
                }
            }
            
            // 3. Delete Attendees
            List<VEM_Attendee__c> attendees = [SELECT Id FROM VEM_Attendee__c];
            if (!attendees.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(attendees, false);
                for (Database.DeleteResult result : results) {
                    if (result.isSuccess()) {
                        attendeeDeleted++;
                    } else {
                        if (result.getErrors() != null && !result.getErrors().isEmpty()) {
                            deleteErrors.add('Attendee delete failed: ' + result.getErrors()[0].getMessage());
                        }
                    }
                }
            }
            
            // 4. Delete Event Consultants
            List<VEM_Event_Consultant__c> eventConsultants = [SELECT Id FROM VEM_Event_Consultant__c];
            if (!eventConsultants.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(eventConsultants, false);
                for (Database.DeleteResult result : results) {
                    if (result.isSuccess()) {
                        eventConsultantDeleted++;
                    } else {
                        if (result.getErrors() != null && !result.getErrors().isEmpty()) {
                            deleteErrors.add('Event Consultant delete failed: ' + result.getErrors()[0].getMessage());
                        }
                    }
                }
            }
            
            // 5. Delete Events
            List<VEM_Event__c> events = [SELECT Id FROM VEM_Event__c];
            if (!events.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(events, false);
                for (Database.DeleteResult result : results) {
                    if (result.isSuccess()) {
                        eventDeleted++;
                    } else {
                        if (result.getErrors() != null && !result.getErrors().isEmpty()) {
                            deleteErrors.add('Event delete failed: ' + result.getErrors()[0].getMessage());
                        }
                    }
                }
            }
            
            String summary = 'Expense Line Items: deleted=' + expenseLineItemDeleted +
                           ' | Expense Headers: deleted=' + expenseHeaderDeleted +
                           ' | Attendees: deleted=' + attendeeDeleted +
                           ' | Event Consultants: deleted=' + eventConsultantDeleted +
                           ' | Events: deleted=' + eventDeleted;
            if (!deleteErrors.isEmpty()) {
                summary += ' | Errors: ' + String.join(deleteErrors, ' | ');
            }
            return summary;
        } catch (Exception e) {
            System.debug('Error deleting events data: ' + e.getMessage());
            return 'Error deleting events data: ' + e.getMessage();
        }
    }
    
    /**
     * Method to create all business data sequentially with rollback on failure
     * Creates: Accounts & Affiliations, Products, Consultants, Events Data
     * @return String Summary of created records or error details
     */
    @AuraEnabled
    public static String createAllBusinessData() {
        List<String> stepsCompleted = new List<String>();
        List<String> errorMessages = new List<String>();
        
        try {
            // Step 1: Create Accounts and Affiliations
            try {
                String result = seedAccountsAndAffiliations();
                if (result.contains('Error') || result.toLowerCase().contains('failed') || 
                    result.contains('Errors:') || result.contains('HCP Errors:') ||
                    result.contains('Affiliation Errors:') || result.contains('Org Address Errors:')) {
                    throw new CalloutException(result);
                }
                stepsCompleted.add('Accounts and Affiliations');
            } catch (Exception e) {
                errorMessages.add('Step 1 (Accounts and Affiliations) failed: ' + e.getMessage());
                rollbackBusinessData(stepsCompleted);
                return 'Failed at Step 1. All data rolled back. Error: ' + String.join(errorMessages, ' | ');
            }
            
            // Step 2: Create Products
            try {
                String result = seedProducts();
                if (result.contains('Error') || result.toLowerCase().contains('failed') || 
                    result.contains('Errors:') || result.contains('Product Errors:')) {
                    throw new CalloutException(result);
                }
                stepsCompleted.add('Products');
            } catch (Exception e) {
                errorMessages.add('Step 2 (Products) failed: ' + e.getMessage());
                rollbackBusinessData(stepsCompleted);
                return 'Failed at Step 2. All data rolled back. Error: ' + String.join(errorMessages, ' | ');
            }
            
            // Step 3: Create Consultants
            try {
                String result = seedConsultantsPublic();
                if (result.contains('Error') || result.toLowerCase().contains('failed') || 
                    result.contains('Errors:') || result.contains('Consultant Errors:')) {
                    throw new CalloutException(result);
                }
                stepsCompleted.add('Consultants');
            } catch (Exception e) {
                errorMessages.add('Step 3 (Consultants) failed: ' + e.getMessage());
                rollbackBusinessData(stepsCompleted);
                return 'Failed at Step 3. All data rolled back. Error: ' + String.join(errorMessages, ' | ');
            }
            
            // Step 4: Create Events Data
            try {
                String result = seedEventsData();
                if (result.contains('Error') || result.toLowerCase().contains('failed') || 
                    result.contains('Errors:') || result.contains('Sales Rep users not found') ||
                    result.contains('Products not found')) {
                    throw new CalloutException(result);
                }
                stepsCompleted.add('Events Data');
            } catch (Exception e) {
                errorMessages.add('Step 4 (Events Data) failed: ' + e.getMessage());
                rollbackBusinessData(stepsCompleted);
                return 'Failed at Step 4. All data rolled back. Error: ' + String.join(errorMessages, ' | ');
            }
            
            return 'Successfully completed all steps: ' + String.join(stepsCompleted, ', ');
        } catch (Exception e) {
            rollbackBusinessData(stepsCompleted);
            return 'Error creating business data: ' + e.getMessage() + ' | Rolled back: ' + String.join(stepsCompleted, ', ');
        }
    }
    
    /**
     * Helper method to rollback business data in reverse order
     * @param stepsCompleted List of steps that were completed and need rollback
     */
    private static void rollbackBusinessData(List<String> stepsCompleted) {
        // Delete in reverse order of creation
        for (Integer i = stepsCompleted.size() - 1; i >= 0; i--) {
            String step = stepsCompleted[i];
            try {
                if (step == 'Events Data') {
                    deleteEventsData();
                } else if (step == 'Consultants') {
                    deleteConsultants();
                } else if (step == 'Products') {
                    deleteProducts();
                } else if (step == 'Accounts and Affiliations') {
                    deleteAccountsAndAffiliations();
                }
            } catch (Exception e) {
                System.debug('Error during rollback of ' + step + ': ' + e.getMessage());
            }
        }
    }
    
    /**
     * Method to delete all business data
     * Deletes: Events Data, Consultants, Products, Accounts and Affiliations
     * @return String Summary of deleted records
     */
    @AuraEnabled
    public static String deleteAllBusinessData() {
            List<String> deleteResults = new List<String>();
            List<String> errorMessages = new List<String>();
            
            // Delete in reverse dependency order
           
                String result = deleteEventsData();
                deleteResults.add('Events Data: ' + result);
           
            
           
                String result2 = deleteConsultants();
                deleteResults.add('Consultants: ' + result2);
           
            
           
                String result3 = deleteProducts();
                deleteResults.add('Products: ' + result3);
            
            
           
                String result4 = deleteAccountsAndAffiliations();
                deleteResults.add('Accounts and Affiliations: ' + result4);
          
            
            String summary = String.join(deleteResults, ' | ');
            if (!errorMessages.isEmpty()) {
                summary += ' | Errors: ' + String.join(errorMessages, ' | ');
            }
            return summary;
    }
}