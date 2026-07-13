/**
 * @description Service to create and delete deterministic VEM seed Users.
 * Identifies seeded Users using FederationIdentifier='VEM_SEED' and Alias prefix 'VEMSEED_'.
 * Provides invocable methods for Flow/LWC integration.
 * Requirements:
 * - with sharing to respect org sharing
 * - Run DML in USER_MODE
 * - Bulkified and exception-safe
 */
public with sharing class VEM_UserSeederService {
    public static final String SEED_FEDERATION_ID = 'VEM_SEED';
    public static final String SEED_ALIAS_PREFIX = 'VEMSEED_';
    public static  Map<String, Map<String, String>> roleDefinitions = new Map<String, Map<String, String>>{
        'VEM_Marketing_Ops' => new Map<String, String>{
            'Name' => 'VEM_Marketing_Ops',
            'Parent' => null
        },
        'VEM_Vendor' => new Map<String, String>{
            'Name' => 'VEM_Vendor',
            'Parent' => 'VEM_Marketing_Ops'
        },
        'VEM_Sales_East_Manager' => new Map<String, String>{
            'Name' => 'VEM_Sales_East_Manager',
            'Parent' => 'VEM_Vendor'
        },
        'VEM_Sales_East_Rep' => new Map<String, String>{
            'Name' => 'VEM_Sales_East_Rep',
            'Parent' => 'VEM_Sales_East_Manager'
        },
        'VEM_Sales_West_Manager' => new Map<String, String>{
            'Name' => 'VEM_Sales_West_Manager',
            'Parent' => 'VEM_Vendor'
        },
        'VEM_Sales_West_Rep' => new Map<String, String>{
            'Name' => 'VEM_Sales_West_Rep',
            'Parent' => 'VEM_Sales_West_Manager'
        }
    };
    public static  List<String> creationOrder = new List<String>{
        'VEM_Marketing_Ops',
        'VEM_Vendor',
        'VEM_Sales_East_Manager',
        'VEM_Sales_East_Rep',
        'VEM_Sales_West_Manager',
        'VEM_Sales_West_Rep'
    };
    public class SeedResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String action; // CREATE or DELETE
        @AuraEnabled public Integer processedCount;
        @AuraEnabled public Integer successCount;
        @AuraEnabled public Integer errorCount;
        @AuraEnabled public List<String> messages;
        public SeedResult() {
            messages = new List<String>();
            success = true;
            processedCount = 0;
            successCount = 0;
            errorCount = 0;
        }
    }

    public class UserSeedSpec {
        public String firstName;
        public String lastName;
        public String roleDeveloperName;
        public String profileApiName;
        public List<String> permSetApiNames;
        public String region;
        public String persona;
        public String usernameLocal; // lex.luthor.vemseed+east
    }

    @AuraEnabled
    public static SeedResult createSeedUsers() {
        SeedResult res = new SeedResult();
        res.action = 'CREATE';
        try {
            // Ensure required roles exist before proceeding
            Map<String, Id> roleCreationResults = ensureRolesExist(res);
            if (!res.success && res.errorCount > 0) {
                return res; // Return early if role creation failed
            }
            
            // Resolve metadata maps
            Map<String, Id> roleByDeveloperName = getRoleMap();
            Map<String, Id> profileByApiName = getProfileMap();
            Map<String, PermissionSet> permSets = getPermSetMap(new Set<String>{
                'VEM_ADMIN','VEM_USER','VEM_VENDOR'
            });

            List<UserSeedSpec> specs = getSeedSpecs();

            // Build users
            List<User> toInsert = new List<User>();
            for (UserSeedSpec spec : specs) {
                User u = new User();
                u.FirstName = spec.firstName;
                u.LastName = spec.lastName;
                u.UserPermissionsSFContentUser = false ;
                u.Alias = makeAlias(spec.firstName, spec.lastName);
                // Ensure FederationIdentifier is unique by appending a random suffix
                u.FederationIdentifier = SEED_FEDERATION_ID + '_' + String.valueOf(Crypto.getRandomInteger()).right(6);
                u.CommunityNickname = (spec.firstName + '.' + spec.lastName + '.vemseed').toLowerCase() + '_' + String.valueOf(Crypto.getRandomInteger()).right(4);
                u.TimeZoneSidKey = 'America/Los_Angeles';
                u.LocaleSidKey = 'en_US';
                u.EmailEncodingKey = 'UTF-8';
                u.LanguageLocaleKey = 'en_US';
             
                //u.UserPreferencesDisableAllFeeds = true;
                u.UserRoleId = roleByDeveloperName.get(spec.roleDeveloperName);
                u.ProfileId = profileByApiName.get(spec.profileApiName);
                // Generate a unique random suffix to ensure username uniqueness
                String randomSuffix = String.valueOf(Crypto.getRandomInteger()).right(6);
                String email = (spec.usernameLocal + '@example.' + randomSuffix + '.invalid').toLowerCase();
                u.Email = email;
                u.Username = (spec.usernameLocal + '@example.' + randomSuffix + '.invalid').toLowerCase();
                // Activate users per requirement. We'll still avoid content licenses by filtering perm sets below.
                u.IsActive = true;
                // Set required name fields again for safety
                u.FirstName = spec.firstName;
                u.LastName = spec.lastName;
                // Title/Department tags for easy identification in UI (non-authoritative)
                u.Title = 'VEM Seed - ' + (spec.persona == null ? '' : spec.persona);
                u.Department = spec.region == null ? null : ('Region: ' + spec.region);
                toInsert.add(u);
            }

            // Execute DML in USER_MODE and allow partial success
            // Using supported overload with allOrNone=false and AccessLevel.USER_MODE
            Database.SaveResult[] sr = Database.insert(toInsert, false, AccessLevel.USER_MODE);
            res.processedCount = sr.size();
            res.successCount = 0;
            res.errorCount = 0;

            // Assign Permission Sets
            // To avoid LICENSE_LIMIT_EXCEEDED errors, ensure we do NOT assign any Content/CRM Content or Knowledge licenses.
            // We'll block known Content-related permission sets by name and keyword patterns.
            // Known Content user permsets often include names like:
            // - Content User
            // Add explicit blocklist plus a defensive keyword check.
            Set<String> blockedExactPsNames = new Set<String>{
                'Content User'
            };
            Set<String> licenseBackedKeywords = new Set<String>{ 'CONTENT', 'CRM CONTENT', 'KNOWLEDGE' };
            List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
            for (Integer i = 0; i < sr.size(); i++) {
                if (sr[i].isSuccess()) {
                    res.successCount++;
                    User created = toInsert[i];
                    // Assign based on persona
                    List<String> psNames = specs[i].permSetApiNames == null ? new List<String>() : specs[i].permSetApiNames;
                    for (String psName : psNames) {
                        PermissionSet ps = permSets.get(psName);
                        if (ps != null) {
                            // Explicitly block known Content license permsets
                            if (blockedExactPsNames.contains(ps.Name)) {
                                res.messages.add('Skipped PermissionSet (blocked exact name): ' + ps.Name + ' for ' + created.Username);
                                continue;
                            }
                            // Defensive keyword block to avoid content/knowledge-backed licenses
                            String psNameUpper = ps.Name == null ? '' : ps.Name.toUpperCase();
                            Boolean looksLicenseBacked = false;
                            for (String kw : licenseBackedKeywords) {
                                if (psNameUpper.contains(kw)) {
                                    looksLicenseBacked = true;
                                    break;
                                }
                            }
                            if (looksLicenseBacked) {
                                res.messages.add('Skipped PermissionSet due to potential license consumption: ' + ps.Name + ' for ' + created.Username);
                                continue;
                            }
                            PermissionSetAssignment psa = new PermissionSetAssignment();
                            psa.PermissionSetId = ps.Id;
                            psa.AssigneeId = sr[i].getId();
                            psaToInsert.add(psa);
                        } else {
                            res.messages.add('Missing PermissionSet ' + psName + ' for ' + created.Username);
                        }
                    }
                } else {
                    res.errorCount++;
                    res.messages.add('Create failed: ' + toInsert[i].Username + ' -> ' + collectErrors(sr[i]));
                }
            }
            if (!psaToInsert.isEmpty()) {
                Database.SaveResult[] psaSr = Database.insert(psaToInsert, false, AccessLevel.USER_MODE);
                for (Integer i = 0; i < psaSr.size(); i++) {
                    if (!psaSr[i].isSuccess()) {
                        res.messages.add('PermSet assign failed: ' + collectErrors(psaSr[i]));
                        res.errorCount++;
                    }
                }
            }
            res.success = res.errorCount == 0;
        } catch (Exception e) {
            res.success = false;
            res.messages.add('Unhandled error: ' + e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static SeedResult deleteSeedUsers() {
        // Note: Users cannot be hard-deleted via DML. We'll deactivate and then anonymize key fields.
        SeedResult res = new SeedResult();
        res.action = 'DELETE';
        try {
            List<User> seeded = [
                SELECT Id, Username, IsActive, CommunityNickname, Email, Alias
                FROM User
                WHERE FederationIdentifier LIKE :SEED_FEDERATION_ID + '%'
                WITH USER_MODE
            ];

            // 1) Deactivate any active seeded users
            List<User> toDeactivate = new List<User>();
            // Find the COO role
            Id cooRoleId = null;
            List<UserRole> cooRoles = [SELECT Id FROM UserRole WHERE Name = 'COO' LIMIT 1];
            if (!cooRoles.isEmpty()) {
                cooRoleId = cooRoles[0].Id;
            }
            // Assign COO role to all seeded users (to be deactivated)
            if (cooRoleId != null) {
                for (User u : seeded) {
                    u.UserRoleId = cooRoleId;
                }
                update seeded;
            }
            for (User u : seeded) {
                if (u.IsActive) {
                    toDeactivate.add(new User(Id = u.Id, IsActive = false));
                }
            }
            if (!toDeactivate.isEmpty()) {
                Database.update(toDeactivate, false, AccessLevel.USER_MODE);
            }

            // 2) "Soft delete" behavior: anonymize seeded users to remove visibility/usage while preserving referential integrity
            // Clear Username and Email to ensure they can't be used to login or collide with duplicates
            // Append random integer to username and set random nickname
            List<User> toAnonymize = new List<User>();
            for (User u : seeded) {
                // Generate a random suffix to make the username and nickname unique
                String randomSuffix = String.valueOf(Crypto.getRandomInteger()).right(6);
                User upd = new User(
                    Id = u.Id,
                    // Keep FederationIdentifier marker to allow idempotent cleanups
                    Email = null,
                    CommunityNickname = 'DELETED_' + randomSuffix,
                    Username = u.Username + '_' + randomSuffix,
                    Alias = ('DEL' + randomSuffix).left(8),
                    Title = 'VEM Seed - Deactivated',
                    Department = null
                );
                toAnonymize.add(upd);
            }
            if (!toAnonymize.isEmpty()) {
                Database.update(toAnonymize, false, AccessLevel.USER_MODE);
            }

            // Report results as if processed; since delete is not allowed, we treat successful deactivation/anonymization as success
            res.processedCount = seeded.size();
            res.successCount = seeded.size();
            res.errorCount = 0;
            res.success = true;
        } catch (Exception e) {
            res.success = false;
            res.errorCount = (res.errorCount == null ? 0 : res.errorCount) + 1;
            res.messages.add('Unhandled error: ' + e.getMessage());
        }
        return res;
    }

    // Helpers

    private static String makeAlias(String first, String last) {
        String base = (first != null ? first : '').left(3) + (last != null ? last : '').left(2);
        base = base.replaceAll('[^A-Za-z0-9]', '');
        base = base.toLowerCase();
        base = (SEED_ALIAS_PREFIX + base);
        return base.length() > 8 ? base.left(8) : base;
    }

    private static Map<String, Id> getRoleMap() {
        Map<String, Id> mapByDevName = new Map<String, Id>();
        for (UserRole r : [SELECT Id, DeveloperName FROM UserRole]) {
            mapByDevName.put(r.DeveloperName, r.Id);
        }
        return mapByDevName;
    }

    private static Map<String, Id> getProfileMap() {
        Map<String, Id> mapByName = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile]) {
            // Using Profile Name equals to file name without extension
            mapByName.put(p.Name, p.Id);
        }
        return mapByName;
    }

    private static Map<String, PermissionSet> getPermSetMap(Set<String> apiNames) {
        if (apiNames == null || apiNames.isEmpty()) {
            return new Map<String, PermissionSet>();
        }
        Map<String, PermissionSet> out = new Map<String, PermissionSet>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :apiNames]) {
            out.put(ps.Name, ps);
        }
        return out;
    }

    private static List<UserSeedSpec> getSeedSpecs() {
        // Using standard Salesforce profiles:
        // Standard User, Standard Platform User
        List<UserSeedSpec> specs = new List<UserSeedSpec>();

        // 1. Lex Luthor - Salesforce - VEM_Sales_East_Rep - Sales Representative
        specs.add(buildSpec('Lex','Luthor','VEM_Sales_East_Rep','Standard Platform User',
            new List<String>{'VEM_USER'}, 'East', 'Sales Representative', 'lex.luthor.vemseed.east'));

        // 2. Victor Von Doom - Salesforce - VEM_Sales_West_Rep - Sales Representative
        specs.add(buildSpec('Victor','Von Doom','VEM_Sales_West_Rep','Standard Platform User',
            new List<String>{'VEM_USER'}, 'West', 'Sales Representative', 'victor.vondoom.vemseed.west'));

        // 3. Norman Osborn - Salesforce Platform - VEM_Sales_East_Manager - Sales Manager
        specs.add(buildSpec('Norman','Osborn','VEM_Sales_East_Manager','Standard Platform User',
            new List<String>{'VEM_USER'}, 'East', 'Sales Manager', 'norman.osborn.vemseed.eastmgr'));

        // 4. Wilson Fisk - Salesforce Platform - VEM_Sales_West_Manager - Sales Manager
        specs.add(buildSpec('Wilson','Fisk','VEM_Sales_West_Manager','Standard Platform User',
            new List<String>{'VEM_USER'}, 'West', 'Sales Manager', 'wilson.fisk.vemseed.westmgr'));

        // 5. Otto Octavius - Salesforce Platform - VEM_Marketing_Ops - Marketing Operations
        specs.add(buildSpec('Otto','Octavius','VEM_Marketing_Ops','Standard User',
            new List<String>{'VEM_ADMIN'}, null, 'Marketing Operations', 'otto.octavius.vemseed.mops'));

        // 6. Thanos Thanos - Salesforce Platform - VEM_Vendor - Vendor (internal platform user)
        specs.add(buildSpec('Thanos','Thanos','VEM_Vendor','Standard User',
            new List<String>{'VEM_VENDOR'}, null, 'Vendor', 'thanos.thanos.vemseed.vendor'));

        return specs;
    }

    private static UserSeedSpec buildSpec(String first, String last, String roleDevName, String profileApiName,
                                          List<String> permSets, String region, String persona, String usernameLocal) {
        UserSeedSpec s = new UserSeedSpec();
        s.firstName = first;
        s.lastName = last;
        s.roleDeveloperName = roleDevName;
        s.profileApiName = profileApiName;
        s.permSetApiNames = permSets;
        s.region = region;
        s.persona = persona;
        s.usernameLocal = usernameLocal;
        return s;
    }

    private static String collectErrors(Database.SaveResult sr) {
        List<String> errs = new List<String>();
        for (Database.Error e : sr.getErrors()) {
            errs.add(e.getStatusCode() + ': ' + e.getMessage());
        }
        return String.join(errs, '; ');
    }
    private static String collectErrors(Database.DeleteResult dr) {
        List<String> errs = new List<String>();
        for (Database.Error e : dr.getErrors()) {
            errs.add(e.getStatusCode() + ': ' + e.getMessage());
        }
        return String.join(errs, '; ');
    }

    /**
     * Ensures all required VEM roles exist, creating them if necessary with proper hierarchy.
     * Hierarchy:
     * - VEM Marketing Operations (top level)
     *   - VEM Vendor
     *     - VEM Sales – East Manager
     *       - VEM Sales – East Rep
     *     - VEM Sales – West Manager
     *       - VEM Sales – West Rep
     * 
     * @param res SeedResult to append messages/errors to
     * @return Map of DeveloperName to Role Id
     */
    private static Map<String, Id> ensureRolesExist(SeedResult res) {
        Map<String, Id> roleMap = new Map<String, Id>();
        
        // Get existing roles - check by both DeveloperName and Name to avoid duplicates
        Map<String, UserRole> existingRolesByDevName = new Map<String, UserRole>();
        Map<String, UserRole> existingRolesByName = new Map<String, UserRole>();
        for (UserRole r : [SELECT Id, DeveloperName, Name, ParentRoleId FROM UserRole]) {
            if (r.DeveloperName != null) {
                existingRolesByDevName.put(r.DeveloperName, r);
            }
            if (r.Name != null) {
                existingRolesByName.put(r.Name, r);
            }
        }
        
        // Define role hierarchy: {DeveloperName: {Name, ParentDeveloperName}}
       
        
        // Create roles in hierarchy order (parent before child)
        // Order: Marketing Ops -> Vendor -> East Manager -> East Rep, West Manager -> West Rep
       
        
        // We need to create roles in batches, ensuring parent roles exist before children
        // Use a Map to track role Ids (existing + newly created)
        Map<String, Id> roleIdMap = new Map<String, Id>();
        for (String devName : existingRolesByDevName.keySet()) {
            roleIdMap.put(devName, existingRolesByDevName.get(devName).Id);
        }
        
        // Create roles one at a time in hierarchy order to ensure parent exists
        for (String devName : creationOrder) {
            // Skip if role already exists by DeveloperName
            if (roleIdMap.containsKey(devName)) {
                roleMap.put(devName, roleIdMap.get(devName));
                continue;
            }
            
            Map<String, String> roleDef = roleDefinitions.get(devName);
            String roleName = roleDef.get('Name');
            
            // Always check for existing role by name right before attempting to create
            // This handles cases where roles might have been created in the same transaction
            List<UserRole> existingRolesWithName = [
                SELECT Id, DeveloperName, Name 
                FROM UserRole 
                WHERE Name = :roleName 
                LIMIT 1
            ];
            
            if (!existingRolesWithName.isEmpty()) {
                // Role with this name already exists - use it
                UserRole existingRole = existingRolesWithName[0];
                roleIdMap.put(devName, existingRole.Id);
                roleMap.put(devName, existingRole.Id);
                res.messages.add('Using existing role with same name: ' + roleName + ' (DeveloperName: ' + existingRole.DeveloperName + ', requested: ' + devName + ')');
                continue;
            }
            
            // Also check by DeveloperName one more time (in case it was just created)
            List<UserRole> existingRolesWithDevName = [
                SELECT Id, DeveloperName, Name 
                FROM UserRole 
                WHERE DeveloperName = :devName 
                LIMIT 1
            ];
            
            if (!existingRolesWithDevName.isEmpty()) {
                UserRole existingRole = existingRolesWithDevName[0];
                roleIdMap.put(devName, existingRole.Id);
                roleMap.put(devName, existingRole.Id);
                res.messages.add('Using existing role with same DeveloperName: ' + devName);
                continue;
            }
            
            UserRole newRole = new UserRole();
            newRole.Name = roleName;
            newRole.DeveloperName = devName;
            
            // Set parent role if specified
            String parentDevName = roleDef.get('Parent');
            if (parentDevName != null) {
                Id parentId = roleIdMap.get(parentDevName);
                if (parentId == null) {
                    res.messages.add('Error: Parent role ' + parentDevName + ' not found for ' + devName);
                    res.errorCount = (res.errorCount == null ? 0 : res.errorCount) + 1;
                    continue;
                }
                newRole.ParentRoleId = parentId;
            }
            
            // Insert role individually to ensure we can use its Id for children
            // Use allOrNone=false to handle duplicates gracefully
            Database.SaveResult sr = Database.insert(newRole, false);
            
            if (sr.isSuccess()) {
                Id roleId = sr.getId();
                roleIdMap.put(devName, roleId);
                roleMap.put(devName, roleId);
                res.messages.add('Created role: ' + newRole.Name + ' (' + devName + ')');
            } else {
                // Check for duplicate errors and query for existing role
                Boolean isDuplicate = false;
                for (Database.Error err : sr.getErrors()) {
                    String errorMsg = err.getMessage();
                    if (err.getStatusCode() == StatusCode.DUPLICATE_MASTER_LABEL || 
                        err.getStatusCode() == StatusCode.DUPLICATE_DEVELOPER_NAME ||
                        errorMsg.contains('DUPLICATE_MASTER_LABEL') ||
                        errorMsg.contains('DUPLICATE_DEVELOPER_NAME') ||
                        errorMsg.contains('label you entered is in use') ||
                        errorMsg.contains('Developer Name already exists')) {
                        isDuplicate = true;
                        break;
                    }
                }
                
                if (isDuplicate) {
                    // Query for existing role
                    List<UserRole> existingRoles = [
                        SELECT Id, DeveloperName, Name 
                        FROM UserRole 
                        WHERE Name = :roleName OR DeveloperName = :devName
                        LIMIT 1
                    ];
                    if (!existingRoles.isEmpty()) {
                        UserRole existingRole = existingRoles[0];
                        roleIdMap.put(devName, existingRole.Id);
                        roleMap.put(devName, existingRole.Id);
                        res.messages.add('Using existing role (duplicate detected): ' + roleName + ' (DeveloperName: ' + existingRole.DeveloperName + ', requested: ' + devName + ')');
                        continue;
                    }
                }
                
                res.errorCount = (res.errorCount == null ? 0 : res.errorCount) + 1;
                res.messages.add('Failed to create role ' + newRole.Name + ' (' + devName + '): ' + collectErrors(sr));
            }
        }
        
        // Check if all required roles exist
        Set<String> missingRoles = new Set<String>();
        for (String devName : creationOrder) {
            if (!roleMap.containsKey(devName) || roleMap.get(devName) == null) {
                missingRoles.add(devName);
            }
        }
        
        if (!missingRoles.isEmpty()) {
            res.success = false;
            if (res.errorCount == null) {
                res.errorCount = 0;
            }
            res.errorCount = res.errorCount + missingRoles.size();
            res.messages.add('Missing required roles: ' + String.join(new List<String>(missingRoles), ', '));
        } else {
            res.messages.add('All required roles verified/created successfully.');
        }
        
        return roleMap;
    }
}