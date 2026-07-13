/**
 * @description Test class for VEM_UserSeederService
 * @author Velmend Events Team
 */
@isTest
private class VEM_UserSeederService_Test {
    
    
    @isTest
    static void testDeleteSeedUsers() {
        VEM_UserSeederService.roleDefinitions = new Map<String, Map<String, String>>{
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
        VEM_UserSeederService.creationOrder = new List<String>{
            'VEM_Marketing_Ops',
            'VEM_Vendor',
            'VEM_Sales_East_Manager',
            'VEM_Sales_East_Rep',
            'VEM_Sales_West_Manager',
            'VEM_Sales_West_Rep'
        };

        // Delete all roles defined in VEM_UserSeederService.roleDefinitions if they exist
        List<UserRole> rolesToDelete = [
            SELECT Id 
            FROM UserRole 
            WHERE DeveloperName IN :VEM_UserSeederService.roleDefinitions.keySet()
        ];
        if (!rolesToDelete.isEmpty()) {
            // INSERT_YOUR_CODE
            // Before deleting roles, reassign all users assigned to these roles to have no role
            List<Id> roleIdsToDelete = new List<Id>();
            for (UserRole role : rolesToDelete) {
                roleIdsToDelete.add(role.Id);
            }
            if (!roleIdsToDelete.isEmpty()) {
                List<User> usersWithRoles = [
                    SELECT Id, UserRoleId
                    FROM User
                    WHERE UserRoleId IN :roleIdsToDelete
                ];
                if (!usersWithRoles.isEmpty()) {
                    for (User u : usersWithRoles) {
                        u.UserRoleId = null;
                    }
                    update usersWithRoles;
                }
            }
            delete rolesToDelete;
        }
        VEM_UserSeederService.createSeedUsers();
        Test.startTest();
        VEM_UserSeederService.deleteSeedUsers();
        Test.stopTest();
    }

    
}