@IsTest
public class ReplicacaoProdutosBatchTest {
    
    @testSetup
    static void setup(){
        
        ParametroDeServicosBatch__c psb = new ParametroDeServicosBatch__c();
        psb.Name = 'ReplicacaoDeProdutos';
        psb.DataUltimaExecucao__c = null;
        psb.QtdeRegistrosProcessados__c = 0;
        
        insert psb;
                    
        Product2 p1 = new Product2();
        p1.Name = 'Teste Prod Major';
        p1.ProductCode = '9960';
        p1.FamiliaECommerce__c = '9960';
        p1.QuantityUnitOfMeasure = 'KG';
        p1.Family = '370';
        p1.Major__c = '5080';
        p1.Minor__c = '9960';
        p1.SuperGroup__c = 'BYN';
        p1.MatType__c = '0BLK';
        p1.Tamanho__c = '';
        p1.Grupo1__c = 'PGP';
        p1.Grupo2__c = 'OUTROS';
        p1.TipoNegocio__c = 'PGP';
        p1.Grupo3__c = 'Industrial';
        p1.IsActive = True;
        p1.Volume__c = 1;
        p1.CapacidadeHidraulica__c = '1';
        p1.DescricaoCurta__c = 'Teste';
        p1.DescricaoLonga__c = 'Teste';
        p1.DisponivelEcommerce__c = TRUE;
        p1.Description = 'teste';
        p1.NCM__c = '2804.30.00';
        insert p1;
        
        Product2 p2 = new Product2();
        p2.Name = 'Teste Prod Minor';
        p2.ProductCode = 'BR6755380099';
        p2.QuantityUnitOfMeasure = 'KG';
        p2.FamiliaECommerce__c = '9960';
        p2.Family = '370';
        p2.Major__c = '';
        p2.Minor__c = '9960';
        p2.SuperGroup__c = 'BYN';
        p2.MatType__c = '0BLK';
        p2.Tamanho__c = '';
        p2.Grupo1__c = 'PGP';
        p2.TipoNegocio__c = 'PGP';
        p2.Grupo2__c = 'OUTROS';
        p2.Grupo3__c = 'Industrial';
        p2.IsActive = True;
        p2.Volume__c = 10;
        p2.CapacidadeHidraulica__c = '2';
        p2.DescricaoCurta__c = 'Teste';
        p2.DescricaoLonga__c = 'Teste';
        p2.Description = 'teste';
        p2.DisponivelEcommerce__c = TRUE;
        p2.NCM__c = '2804.30.00';
        insert p2;
        
    }
    
    static testmethod void teste(){
        Test.startTest();
        ReplicacaoProdutosBatch rpb = new ReplicacaoProdutosBatch();
        id t = Database.executeBatch(rpb);
        Test.stopTest();   
        //system.assertEquals(2, [SELECT count() From ccrz__E_Product__c]);
        //System.debug('select de produtos' + [SELECT name From ccrz__E_Product__c]);
    }
    
}