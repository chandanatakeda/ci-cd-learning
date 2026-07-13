/**
 * @description Test class for VEM_DataSeederService
 * @author Velmend Events Team
 */
@isTest
public class VEM_DataSeederService_Test {

    @TestSetup
    static void makeData() {
        VEM_UserSeederService.deleteSeedUsers();
        VEM_UserSeederService.createSeedUsers();
    }

    @isTest
    static void testCreateAllBusinessDataAndDelete() {
        Test.startTest();
        VEM_DataSeederService.createAllBusinessData();
        Test.stopTest();
        VEM_DataSeederService.deleteAllBusinessData();
    }

    @isTest
    static void testSeedProductsAndDeleteProducts() {
        Test.startTest();
        String createResult = VEM_DataSeederService.seedProducts();
        String deleteResult = VEM_DataSeederService.deleteProducts();
        Test.stopTest();

    }

    @isTest
    static void testDeleteProductsWhenEmpty() {
        Test.startTest();
        String result = VEM_DataSeederService.deleteProducts();
        Test.stopTest();
        System.assert(result != null);
    }

    @isTest
    static void testSeedAccountsAndAffiliationsAndAddressesAndDelete() {
        Test.startTest();
        String affResult = VEM_DataSeederService.seedAccountsAndAffiliations();
        String addrResult = VEM_DataSeederService.seedAddresses();
        String deleteResult = VEM_DataSeederService.deleteAccountsAndAffiliations();
        Test.stopTest();

    }

    @isTest
    static void testSeedConsultantsAndDeleteConsultants() {
        VEM_DataSeederService.seedAccountsAndAffiliations();
        Test.startTest();
        String createResult = VEM_DataSeederService.seedConsultantsPublic();
        String deleteResult = VEM_DataSeederService.deleteConsultants();
        Test.stopTest();
        
        VEM_DataSeederService.deleteAccountsAndAffiliations();
    }

    @isTest
    static void testDeleteConsultantsWhenEmpty() {
        Test.startTest();
        String result = VEM_DataSeederService.deleteConsultants();
        Test.stopTest();
        
    }

    @isTest
    static void testSeedEventsDataAndDeleteEventsData() {
        VEM_DataSeederService.seedAccountsAndAffiliations();
        VEM_DataSeederService.seedProducts();
        VEM_DataSeederService.seedConsultantsPublic();
        Test.startTest();
        String createResult = VEM_DataSeederService.seedEventsData();
        String deleteResult = VEM_DataSeederService.deleteEventsData();
        Test.stopTest();
       
        VEM_DataSeederService.deleteConsultants();
        VEM_DataSeederService.deleteProducts();
        VEM_DataSeederService.deleteAccountsAndAffiliations();
    }

    @isTest
    static void testSeedEventsDataWhenNoSalesReps() {
        List<User> reps = [
            SELECT Id FROM User
            WHERE UserRole.Name IN ('VEM_Sales_East_Rep', 'VEM_Sales_West_Rep')
            AND IsActive = true
        ];
        for (User u : reps) {
            u.IsActive = false;
        }
        update reps;
        Test.startTest();
        String result = VEM_DataSeederService.seedEventsData();
        Test.stopTest();
       
        for (User u : reps) {
            u.IsActive = true;
        }
        update reps;
    }

    @isTest
    static void testSeedEventsDataWhenNoProducts() {
        VEM_DataSeederService.seedAccountsAndAffiliations();
        VEM_DataSeederService.seedConsultantsPublic();
        VEM_DataSeederService.deleteProducts();
        Test.startTest();
        String result = VEM_DataSeederService.seedEventsData();
        Test.stopTest();
        
        VEM_DataSeederService.deleteConsultants();
        VEM_DataSeederService.deleteAccountsAndAffiliations();
    }

   

    @isTest
    static void testDeleteAllBusinessDataPartial() {
        VEM_DataSeederService.seedProducts();
        Test.startTest();
        String result = VEM_DataSeederService.deleteAllBusinessData();
        Test.stopTest();
       
    }
}