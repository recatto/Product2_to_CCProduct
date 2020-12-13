global class ReplicacaoProdutosBatch  implements Database.Batchable<sObject> {
    
    final Date data = Date.today();
    global final String query;
    global Integer qtdRegistros = 0;
    global List <ccrz__E_Product__c> listProdPai = new List <ccrz__E_Product__c>();
    global List <ccrz__E_Product__c> listProdFilho = new List <ccrz__E_Product__c>();
    
    /*
        Nesse caso em específico, o cliente possui alguns campos personalizados para o OOTB Product2. Atenção especial para os campos __c que poderão ser diferentes
        em cada cliente
        Na query realizamos o filtro pelo tipo de negócio que o Product2 é utilizado e um campo Checkbox se o produto ficará disponível no B2B.
    */

    global ReplicacaoProdutosBatch () {   
        this.query = 'SELECT ID, Name, Description, ProductCode, Family, Major__c, Minor__c, MaterialGroup__c, SuperGroup__c, 	MatType__c, Tamanho__c, ' +
            'Grupo1__c, TipoNegocio__c, Grupo2__c, Grupo3__c, IsActive, QuantityUnitOfMeasure, NCM__c, DisponivelEcommerce__c, ' +
            'DescricaoCurta__c, DescricaoLonga__c, Volume__c, FamiliaECommerce__c ' +
            'FROM Product2 ' +
            'WHERE DisponivelEcommerce__c = TRUE AND TipoNegocio__c != \'OUTROS\' ';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }
    
    global void execute(Database.BatchableContext BC, List<Product2> scope) {            
        List<ccrz__E_CompositeProduct__c> listComposite = new List<ccrz__E_CompositeProduct__c>();
        
        //Insere todos os produtos recebidos no escopo
        insereProd(scope);
        
        List<ccrz__E_Product__c> lstProd = [
            SELECT Id, ccrz__SKU__c, Tipo__c, ProdutoReferencia__r.CapacidadeHidraulica__c, ProdutoReferencia__r.FamiliaECommerce__c, ProdutoReferencia__r.Volume__c,ProdutoReferencia__c
            FROM ccrz__E_Product__c
        ];
        
        Map<String, List<ccrz__E_Product__c>> mProdFilhos = new Map <String, List<ccrz__E_Product__c>>();
        for(ccrz__E_Product__c pr : lstProd){
            //lista dos 
            List<ccrz__E_Product__c> idFilhos = new List<ccrz__E_Product__c>();
            //verifico se é um pai
            if(!pr.ccrz__SKU__c.contains('BR')){
                for(ccrz__E_Product__c pr2 : lstProd){
                    if(pr2.ccrz__SKU__c.contains('BR') && pr.ccrz__SKU__c == pr2.ProdutoReferencia__r.FamiliaECommerce__c){
                        idFilhos.add(pr2);
                    }
                }
                mProdFilhos.put(pr.ccrz__SKU__c,idFilhos);
            }
        }
        
        for(ccrz__E_Product__c ccProdP : lstProd){
			List<ccrz__E_Product__c> pfilhos = new List<ccrz__E_Product__c>();

            if(!ccProdP.ccrz__SKU__c.contains('BR')){ // se é pai
                
                pfilhos = mProdFilhos.get(ccProdP.ccrz__SKU__c); // pega a lista de filhos
                if(pfilhos.size() > 0){ // possui filhos
                    
                    Set<String> setFilhos = new Set<String>();
                    for(ccrz__E_Product__c ccProdF:pfilhos){ //para cada filho
                        if(!setFilhos.contains(ccProdF.ccrz__SKU__c +'-'+ccProdP.ccrz__SKU__c)){
                        
                               //cria o composite product
                               ccrz__E_CompositeProduct__c cp = new ccrz__E_CompositeProduct__c();
                               cp.ccrz__Component__c = ccProdF.id;
                               cp.ccrz__Composite__c = ccProdP.id;
                               cp.ccrz__CompositeProductId__c = ccProdF.ccrz__SKU__c +'-'+ccProdP.ccrz__SKU__c;
                               listComposite.add(cp);
                               setFilhos.add(cp.ccrz__CompositeProductId__c);
                        }
                    }
                    
                }
            }
        }
        upsert listComposite ccrz__CompositeProductId__c;
        
        //Atualiza data da ultima execução
        ParametroDeServicosBatch__c psb = [SELECT Id, DataUltimaExecucao__c, QtdeRegistrosProcessados__c FROM ParametroDeServicosBatch__c Where Name = 'ReplicacaoDeProdutos' LIMIT 1];
        psb.DataUltimaExecucao__c = DateTime.now();
        psb.QtdeRegistrosProcessados__c = qtdRegistros;
        update(psb);
        
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    private void insereProd(List<Product2> lstProd){
        
        List<ccrz__E_Product__c> lstProdAdd = new List<ccrz__E_Product__c>(); 
        
        for(Product2 p : lstProd){
            ccrz__E_Product__c ccProd = new ccrz__E_Product__C();
            //ccProd.Name = p.Description;
            ccProd.ccrz__SKU__c = p.ProductCode;
            if(p.MaterialGroup__c == 'EQUIPAMENTO'){
                ccProd.Tipo__c = 'EQUIPAMENTO';
            }else{
                ccProd.Tipo__c = p.TipoNegocio__c;
            }
            ccProd.ccrz__Storefront__c = 'DefaultStore';
            ccProd.ccrz__StartDate__c = data;
            ccProd.ccrz__EndDate__c = data.addYears(99);
            ccProd.ProdutoReferencia__c = p.Id;
            ccProd.Minor__c = p.FamiliaECommerce__c;
            if(ccProd.Tipo__c == 'PGP' || ccProd.Tipo__c == 'EQUIPAMENTO'){
                ccProd.ccrz__UnitOfMeasure__c = 'Cada';
            }else{
                ccProd.ccrz__UnitOfMeasure__c = p.QuantityUnitOfMeasure;
            }
            
            ccProd.ccrz__ProductStatus__c = 'Released';
            //ccProd.ccrz__ShortDescRT__c = p.DescricaoCurta__c;
            ccProd.ccrz__LongDescRT__c = p.DescricaoLonga__c;           
            
            if(p.FamiliaECommerce__c.equalsIgnoreCase(p.ProductCode)){
                ccProd.ccrz__ProductType__c = 'Aggregated'; 
                ccProd.Name = p.DescricaoCurta__c;
                listProdPai.add(ccProd);
            }else{
                ccProd.ccrz__ProductType__c = 'Product';
                
                String n = '';
                if(p.Description.length() > 80){
                    n = p.Description.substring(0, 80);
                }else{
                    n = p.Description;
                }
                ccProd.Name = n;
                listProdFilho.add(ccProd);
            }
            
            lstProdAdd.add(ccProd);
        }
        qtdRegistros++;
        upsert lstProdAdd ccrz__SKU__c;
        
    }
    
}