var exec = require("cordova/exec");

function WXPay() {};

WXPay.prototype.payment = function (success,fail,option) {
    exec(success, fail, 'CDVWxpay', 'payment', option);
};

var wxpay = new WXPay();
module.exports = wxpay;
