import TransactionHelper from "../TransactionHelper/OstTransactionHelper"
import {OstTransactionHelper , OstTransactionExecutor} from "../TransactionHelper/OstTransactionHelper";
import OstWalletSdk from '../OstWalletSdk';

const duration = 60*10;


class OstRedemptionTransactionHelper extends OstTransactionHelper{
    constructor(){
        super();
    }

    executeDirectTransfer(userId, amounts, addresses, txMeta, redemptionDetails,  transferDelegate) {
        let obj = new OstRedemptionTransactionExecutor(userId, 'direct transfer', amounts, addresses, txMeta, redemptionDetails, transferDelegate);
        obj.perform();
        return obj.uuid;
      }
}

class OstRedemptionTransactionExecutor extends OstTransactionExecutor {

    constructor(userId, ruleName, amounts, addresses, txMeta, redemptionDetails, transferDelegate ){
        super(userId, ruleName, amounts, addresses, txMeta, transferDelegate);
        this.redemptionDetails =  redemptionDetails ;
    }

    getSpedingLimitAndExpiryTimeBucket(){
        let validBucket = super.getSpedingLimitAndExpiryTimeBucket();
        if (!TransactionHelper.isExternalConfig ) {
            if( !validBucket ){
                validBucket = {
                    spending_limit: this.totalTxAmount,
                    expiration_time: duration
                }
            }
        }  
        return validBucket;
    }

    callExecuteTransfer(delegate){
        OstWalletSdk.executeTransaction(
            this.userId,
            this.addresses,
            this.decimalAmounts,
            this.ruleName,
            this.txMeta,
            delegate,
            {"redemption_meta": this.redemptionDetails}
          )
    }

}


export default new OstRedemptionTransactionHelper() ; 