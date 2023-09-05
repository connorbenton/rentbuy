<script setup lang="ts">
import { ref, watch, reactive, computed, nextTick } from 'vue'
import { resourceLimits } from 'worker_threads';
import { vMaska } from 'maska'
import { useDisplay } from 'vuetify';
import { useStorage } from '@vueuse/core'
import { reverse } from 'dns';
import { format } from 'path';
import { json } from 'stream/consumers';
import { exportAllDeclaration, numberLiteralTypeAnnotation } from '@babel/types';
import dJSON from 'dirty-json';

const { md, smAndDown, mdAndUp, mobile } = useDisplay()
// Rules for evaluating form input
const rules = {
  down: (value: number) => (rawVar.downTotalRaw / rawVar.priceRaw >= 0.2 && rawVar.downTotalRaw / rawVar.priceRaw < 1 && downCheck) || 'Total Down payment must be at least 20 and not more than 100 percent',
  downOwn: (value: number) => (Number(value) >= 10 && Number(value) < 100) || 'Down payment own funds must be at least 10 percent',
  second: (value: number) => (Number(value) <= 15 && Number(value) > 0 && Number.isInteger(Number(value))) || 'Amortisation must be an integer between 1 and 15 years',
  positiveInteger: (value: number) => (Number.isInteger(Number(value)) && Number(value) > 0) || 'Value must be a positive integer',
  yearsInProperty: (value: number) => (Number.isInteger(Number(value)) && Number(value) > 0 && Number(value) < 51) || 'Value must be a integer between 1 and 50 years',
  rate: (value: string) => (Number.isFinite(Number(value)) && Number(value) >= -50 && Number(value) <= 50 && value != "") || 'Value must be a number between -50 and 50',
  posrate: (value: string) => (Number.isFinite(Number(value)) && Number(value) >= 0 && Number(value) <= 20 && value != "") || 'Value must be a number between 0 and 20',
  numberIn100: (value: string) => (Number.isFinite(Number(value)) && value != "" && Number(value) >= 0 && Number(value) < 100) || 'Value must be a number between 0 and 100'
}

const form = ref()
// form.value = true

// const count = ref(0)

// async function increment() {
//   count.value++

//   // DOM not yet updated
//   console.log(rawVar.downTotalRaw.value) // 0

//   // DOM is now updated
//   console.log(rawVar.downTotalRaw.value) // 1
// }

// hashing the data
const cyrb53 = (str: string, seed = 0) => {
  let h1 = 0xdeadbeef ^ seed, h2 = 0x41c6ce57 ^ seed;
  for (let i = 0, ch; i < str.length; i++) {
    ch = str.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
  h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
  h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);

  return 4294967296 * (2097151 & h2) + (h1 >>> 0);
};

var currentHashVal = window.location.pathname.replace(/\//g, '');

const saveStates = reactive({
  list: useStorage("list", [] as any[]),
  notificationsCount: 0,
});


async function hash() {
  var allData = {
    rawVar: {},
    comVar: {},
    initVar: {},
  };
  allData.rawVar = rawVar;
  allData.comVar = comVar;
  allData.initVar = initVar;

  let strAllData = JSON.stringify(allData);
  let strCom = btoa(JSON.stringify(comVar));
  let strRaw = btoa(JSON.stringify(rawVar));
  let strInit = btoa(JSON.stringify(initVar));

  let hashVal = cyrb53(strAllData);
  if ((hashVal).toString() == currentHashVal) { return; }
  let url = 'https://o3dpyfo8of.execute-api.eu-central-1.amazonaws.com/prod';

  let stringifiedBody = JSON.stringify({
    dataUUID: hashVal,
    comVar: strCom,
    rawVar: strRaw,
    initVar: strInit
  })

  stringifiedBody = stringifiedBody.replace(/(\r\n|\n|\r)/gm, "");

  let response = await fetch(url, {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json;charset=UTF-8'
    },
    body: stringifiedBody
  });
  let responseOK = response && response.ok;
  if (responseOK) {
    let data = await response.json();
    history.pushState({}, "", document.location.origin + "/" + hashVal)
    currentHashVal = hashVal.toString();
    // console.log(data);
    var rawToStore = Object.assign({}, rawVar);
    var initToStore = Object.assign({}, initVar);
    const saveStateNew = {
      id: hashVal.toString(),
      text1: initVar.priceInput.toLocaleString(),
      text2: initVar.rentInput.toLocaleString(),
      rawVar: rawToStore,
      initVar: initToStore,
    }

    saveStates.list.push(saveStateNew);
    blinkList();
    // do something with data
  }
  else {
    //TODO show a error box at top saying that there was a problem with saving data?
  }
  return cyrb53(JSON.stringify(allData));
}

function blinkList() {
    saveListBlink.value = 'elevated'
  setTimeout(()=>{
    saveListBlink.value = 'outlined'
  },350);
}

window.onpopstate = function () {
  GetDynamoData();
}

const saveListBlink = reactive({ value: 'outlined' });

// watch(saveStates, (newVal, oldVal) => {
//   newVal.list.forEach(function (state) {
//     console.log("for " + state.text + " rent raw:");
//     console.log(state.rawVar.rentRaw);
//   })
// })


const isFetching = reactive({ value: false });

const GetDynamoData = async () => {
  var link = document.location.href.split('/');
  var id = link[3];
  if (id === "") return;
  let url = 'https://o3dpyfo8of.execute-api.eu-central-1.amazonaws.com/prod/' + id;

  isFetching.value = true;

  let response = await fetch(url, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json;charset=UTF-8'
    }
  });
  let responseOK = response && response.ok;
  if (responseOK) {
    let data = await response.json();
    // console.log(data);
    if (data.dataHashes.length > 0) {

      var i = JSON.parse(atob((data.dataHashes[0].initVar)));
      var r = JSON.parse(atob((data.dataHashes[0].rawVar)));
      var c = JSON.parse(atob((data.dataHashes[0].comVar)));

      Object.keys(initVar).forEach((key: string) => {
        initVar[key as keyof typeof initVar] = i[key];
      });
      Object.keys(rawVar).forEach((key: string) => {
        rawVar[key as keyof typeof rawVar] = r[key];
      });
      // Object.keys(comVar).forEach((key:string) => {
      //   comVar[key as keyof typeof comVar] = c[key];
      // });

    }

    var rawToStore = Object.assign({}, rawVar);
    var initToStore = Object.assign({}, initVar);
    const saveStateNew = {
      id: id.toString(),
      text1: initVar.priceInput.toLocaleString(),
      text2: initVar.rentInput.toLocaleString(),
      rawVar: rawToStore,
      initVar: initToStore,
    }
    const m = saveStates.list.findIndex(_element => _element.id === id);
    if (m > -1) { } // (2)
    else { saveStates.list.push(saveStateNew); blinkList();}

  }
  else {
    // TODO show a box at the top saying 'error loading data' and use defaults
  }
  isFetching.value = false;
  // console.log(isFetching.value)
}

GetDynamoData()

//Raw variables for computations
var rawVar = reactive({
  priceRaw: 0,
  rentRaw: 0,
  downTotalRaw: 0,
  downOwnRaw: 0,
  downSecondRaw: 0,
  initialMortgageRaw: 0,
  initialFirstRaw: 0,
  initialSecondRaw: 0,
  firstMonthlyRaw: 0,
  secondMonthlyRaw: 0,
  upfrontCostsRaw: 0,
  maintRaw: 0,
  marginalRaw: 0,
  marginalOnlyFirstRaw: 0,
  eigenRaw: 0,
  eigenValue: 0,
  propTaxRaw: 0,
  firstInterestRaw: 0,
  secondInterestRaw: 0,
  secondAmortisationRaw: 0,
  initTotalRaw: 0,
  recurringTotalRaw: 0,
  equityRaw: 0,
  netBuyRaw: 0,
  netRentRaw: 0,
  salePriceRaw: 0,
  realEstateFeeAmountRaw: 0,
  totalGainRaw: 0,
  gainsTaxRaw: 0,
  sellingCostRaw: 0,
  totalRentPaidRaw: 0,
  finalRentRaw: 0,
  investDownRaw: 0,
  investRecurDeltaRaw: 0,

})


watch(
  () => rawVar.downTotalRaw, (value) => {
    // console.log(form.value)
    if (form.value != undefined) form.value.validate()
    // console.log(`total down is: ${value}`)
  })

async function validate() {
  const { valid } = await form.value.validate()

  if (valid) alert('Form is valid')
}
// Computed variables 
var downCheck = false;

var comVar = reactive({

  priceDisplay: computed(() => {
    rawVar.priceRaw = parseInt(initVar.priceInput.toString().replace(/,/g, ''), 10);
    return rawVar.priceRaw.toLocaleString();
  }),
  downOwnDisplay: computed(() => {
    rawVar.downOwnRaw = (comVar.downOwnInputCom / 100 * rawVar.priceRaw);
    return rawVar.downOwnRaw.toLocaleString();
  }),
  upfrontCostsInputCom: computed(() => {
    var x = Number(initVar.upfrontCostsInput);
    if (x < 0 || x > 20) { return 0; }
    else { return initVar.upfrontCostsInput; }
  }),
  downSecondInputCom: computed(() => {
    var x = Number(initVar.downSecondInput);
    var y = Number(initVar.downOwnInput);
    if (x < 10 || x > 100 || (x + y > 100)) { downCheck = false; return 0; }
    else { downCheck = true; return initVar.downSecondInput; }
  }),
  downOwnInputCom: computed(() => {
    var y = Number(initVar.downSecondInput);
    var x = Number(initVar.downOwnInput);
    if (x < 10 || x > 100 || (x + y > 100)) { downCheck = false; return 0; }
    else { downCheck = true; return initVar.downOwnInput; }
  }),
  downSecondDisplay: computed(() => {
    rawVar.downSecondRaw = (comVar.downSecondInputCom / 100 * rawVar.priceRaw);
    return rawVar.downSecondRaw.toLocaleString();
  }),
  downTotalInput: computed(() => { return parseInt(initVar.downSecondInput.toString()) + parseInt(initVar.downOwnInput.toString()) }),
  downTotalDisplay: computed(() => {
    rawVar.downTotalRaw = (rawVar.downOwnRaw + rawVar.downSecondRaw);
    return rawVar.downTotalRaw.toLocaleString();
  }),
  mortgageRateCom: computed(() => {
    if ((initVar.mortgageRateInput < -50) || (initVar.mortgageRateInput > 50)) {
      return 1;
    } else {
      return Number(initVar.mortgageRateInput);
    }
  }),
  initialMortgagedAmount: computed(() => {
    rawVar.initialMortgageRaw = (rawVar.priceRaw - rawVar.downTotalRaw);
    return rawVar.initialMortgageRaw.toLocaleString();
  }),
  initialFirstAmount: computed(() => {
    rawVar.initialFirstRaw = (Math.min(rawVar.initialMortgageRaw, rawVar.priceRaw * 0.67));
    return rawVar.initialFirstRaw.toLocaleString();
  }),
  initialSecondAmount: computed(() => {
    rawVar.initialSecondRaw = (Math.max(rawVar.initialMortgageRaw - rawVar.initialFirstRaw, 0));
    return rawVar.initialSecondRaw.toLocaleString();
  }),
  firstMonthly: computed(() => {
    rawVar.firstMonthlyRaw = (Math.round(rawVar.firstInterestRaw / 12));
    return rawVar.firstMonthlyRaw.toLocaleString();
  }),
  secondMonthly: computed(() => {
    rawVar.secondMonthlyRaw = (Math.round(rawVar.secondInterestRaw / 12 + rawVar.secondAmortisationRaw / 12));
    return rawVar.secondMonthlyRaw.toLocaleString();
  }),
  upfrontCostsAmount: computed(() => {
    rawVar.upfrontCostsRaw = (comVar.upfrontCostsInputCom / 100 * rawVar.priceRaw);
    return rawVar.upfrontCostsRaw.toLocaleString();
  }),
  maintAmount: computed(() => {
    if (initVar.maintInput < 0 || initVar.maintInput > 20) {
      rawVar.maintRaw = (0.75 / 100 * rawVar.priceRaw)
    }
    else {
      rawVar.maintRaw = (initVar.maintInput / 100 * rawVar.priceRaw);
    }
    return rawVar.maintRaw.toLocaleString();
  }),
  marginalAmount: computed(() => {
    var x = initVar.marginalInput;
    if (x < 0 || x >= 100) { rawVar.marginalRaw = 0 }
    else {
      rawVar.marginalRaw = (initVar.marginalInput / 100 * (rawVar.eigenRaw - rawVar.maintRaw - rawVar.firstInterestRaw - rawVar.secondInterestRaw));
    }
    return rawVar.marginalRaw.toLocaleString();
  }),
  marginalOnlyFirstAmount: computed(() => {
    var x = initVar.marginalInput;
    if (x < 0 || x >= 100) { rawVar.marginalOnlyFirstRaw = 0 }
    else {
      rawVar.marginalOnlyFirstRaw = (initVar.marginalInput / 100 * (rawVar.eigenRaw - rawVar.maintRaw - rawVar.firstInterestRaw));
    }
    return rawVar.marginalOnlyFirstRaw.toLocaleString();
  }),
  eigenAmount: computed(() => {
    var x = initVar.eigenInput;
    if (x < 0 || x > 100) {
      rawVar.eigenRaw = 0;
    }
    else {
      rawVar.eigenRaw = (initVar.eigenInput / 100 * .0425 * rawVar.priceRaw);
    }
    return rawVar.eigenRaw.toLocaleString();
  }),
  eigenValue: computed(() => {
    var x = initVar.eigenInput;
    if (x < 0 || x > 100) {
      rawVar.eigenValue = 0;
    }
    else {
      rawVar.eigenValue = (initVar.eigenInput / 100 * rawVar.priceRaw);
    }
    return rawVar.eigenValue.toLocaleString();
  }),
  propTaxAmount: computed(() => {
    if (initVar.propTaxInput < 0 || initVar.propTaxInput > 20) {
      rawVar.propTaxRaw = 0;
      return rawVar.propTaxRaw.toLocaleString();
    } else {
      rawVar.propTaxRaw = (initVar.propTaxInput / 100 * rawVar.priceRaw);
      return rawVar.propTaxRaw.toLocaleString();
    }
  }),
  firstInterest: computed(() => {
    rawVar.firstInterestRaw = (comVar.mortgageRateCom / 100 * rawVar.initialFirstRaw);
    return rawVar.firstInterestRaw.toLocaleString();
  }),
  secondInterest: computed(() => {
    rawVar.secondInterestRaw = ((comVar.mortgageRateCom + comVar.secondPremiumCom) / 100 * rawVar.initialSecondRaw);
    return rawVar.secondInterestRaw.toLocaleString();
  }),
  secondLengthCom: computed(() => {
    return Number(initVar.secondMortgageAmortizationLength);
  }),
  secondAmortisation: computed(() => {
    rawVar.secondAmortisationRaw = (rawVar.initialSecondRaw / comVar.secondLengthCom);
    return Math.round(rawVar.secondAmortisationRaw).toLocaleString();
  }),
  investCom: computed(() => {
    if ((initVar.investInput < -50) || (initVar.investInput > 50)) {
      return 1;
    } else {
      return Number(initVar.investInput);
    }
  }),
  houseRateCom: computed(() => {

    if ((initVar.houseRateInput < -50) || (initVar.houseRateInput > 50)) {
      return 1;
    } else {
      return Number(initVar.houseRateInput);
    }
  }),
  rentRateCom: computed(() => {

    if ((initVar.rentRateInput < -50) || (initVar.rentRateInput > 50)) {
      return 1;
    } else {
      return Number(initVar.rentRateInput);
    }
  }),
  finalRent: computed(() => {
    return Math.round((rawVar.finalRentRaw)).toLocaleString();
  }),
  totalRentPaid: computed(() => {
    rawVar.rentRaw = parseInt(initVar.rentInput.toString().replace(/,/g, ''), 10);
    var x = 0;
    var currentYearRent = rawVar.rentRaw;
    for (var i = 0; i < comVar.yearsTotalCom; i++) {
      x = x + currentYearRent * 12;
      currentYearRent = currentYearRent * (1 + Number(comVar.rentRateCom) / 100);
      rawVar.finalRentRaw = currentYearRent;
    }
    rawVar.totalRentPaidRaw = x;
    return Math.round((rawVar.totalRentPaidRaw)).toLocaleString();
  }),

  investDown: computed(() => {
    var x = rawVar.downOwnRaw + rawVar.upfrontCostsRaw;
    for (var i = 0; i < comVar.yearsTotalCom; i++) {
      x = x * (1 + Number(comVar.investCom) / 100);
    }
    rawVar.investDownRaw = x;
    return Math.round((rawVar.investDownRaw)).toLocaleString();
  }),

  investDownSign: computed(() => {
    if (rawVar.investDownRaw >= 0) { return "green-accent-2" } else return "red-accent-1"
  }),
  investRecurSign: computed(() => {
    if (rawVar.investRecurDeltaRaw >= 0) { return "green-accent-2" } else return "red-accent-1"
  }),

  netBuySign: computed(() => {
    if (rawVar.netBuyRaw <= 0) { return "green-accent-2" } else return "red-accent-1"
  }),
  netRentSign: computed(() => {
    if (rawVar.netRentRaw <= 0) { return "green-accent-2" } else return "red-accent-1"
  }),


  investRecurDelta: computed(() => {

    rawVar.rentRaw = parseInt(initVar.rentInput.toString().replace(/,/g, ''), 10);
    var x = 0;
    var currentYearRent = rawVar.rentRaw;
    for (var i = 0; i < comVar.yearsTotalCom; i++) {
      if (i < comVar.secondLengthCom) {
        var diffCost = comVar.recurringYearlyCostBeforeSecondDone - (currentYearRent * 12);
      } else {
        var diffCost = comVar.recurringYearlyCostAfterSecondDone - (currentYearRent * 12);
      }
      x = x + diffCost;
      x = x * (1 + Number(comVar.investCom) / 100);
      currentYearRent = currentYearRent * (1 + Number(comVar.rentRateCom) / 100);
    }
    rawVar.investRecurDeltaRaw = x;
    return Math.round((rawVar.investRecurDeltaRaw)).toLocaleString();
  }),

  yearsTotalCom: computed(() => {
    if ((initVar.yearsInProperty < 1) || (initVar.yearsInProperty > 50)) {
      return 1;
    } else {
      return Number(initVar.yearsInProperty);
    }
  }),
  secondPremiumCom: computed(() => {
    if ((initVar.secondPremiumInput < -50) || (initVar.secondPremiumInput > 50)) {
      return 1;
    } else {
      return Number(initVar.secondPremiumInput);
    }
  }),

  salePrice: computed(() => {
    rawVar.salePriceRaw = Math.round((rawVar.priceRaw * ((comVar.houseRateCom / 100 + 1) ** comVar.yearsTotalCom)));
    return rawVar.salePriceRaw.toLocaleString();
  }),

  realEstateFeeAmount: computed(() => {
    rawVar.realEstateFeeAmountRaw = rawVar.salePriceRaw * (initVar.realEstateFeeInput / 100);
    return Math.round(rawVar.realEstateFeeAmountRaw).toLocaleString();
  }),
  totalGain: computed(() => {
    rawVar.totalGainRaw = rawVar.salePriceRaw - rawVar.priceRaw;
    return rawVar.totalGainRaw.toLocaleString();
  }),
  gainsTaxAmount: computed(() => {
    rawVar.gainsTaxRaw = Math.round(rawVar.totalGainRaw * (initVar.gainsTaxInput / 100));
    return rawVar.gainsTaxRaw.toLocaleString();
  }),

  initTotal: computed(() => {
    rawVar.initTotalRaw = (rawVar.downTotalRaw + rawVar.upfrontCostsRaw);
    return Math.round(rawVar.initTotalRaw).toLocaleString();
  }),

  recurringYearlyCostBeforeSecondDone: computed(() => {
    return (rawVar.maintRaw + rawVar.secondAmortisationRaw + rawVar.secondInterestRaw + rawVar.firstInterestRaw + rawVar.marginalRaw + rawVar.propTaxRaw);
  }),

  recurringYearlyCostAfterSecondDone: computed(() => {
    return (rawVar.firstInterestRaw + rawVar.maintRaw + rawVar.marginalOnlyFirstRaw + rawVar.propTaxRaw);
  }),

  recurringTotal: computed(() => {
    if (comVar.yearsTotalCom > comVar.secondLengthCom) {
      rawVar.recurringTotalRaw = comVar.secondLengthCom * comVar.recurringYearlyCostBeforeSecondDone + (comVar.yearsTotalCom - comVar.secondLengthCom) * comVar.recurringYearlyCostAfterSecondDone;
    } else {
      rawVar.recurringTotalRaw = comVar.yearsTotalCom * comVar.recurringYearlyCostBeforeSecondDone;
    }
    return Math.round(rawVar.recurringTotalRaw).toLocaleString();
  }),
  equity: computed(() => {
    rawVar.equityRaw = (rawVar.totalGainRaw + rawVar.downTotalRaw + Math.min(initVar.secondMortgageAmortizationLength, comVar.yearsTotalCom) * rawVar.secondAmortisationRaw);
    return Math.round(rawVar.equityRaw).toLocaleString();
  }),
  sellingCostAmount: computed(() => {
    rawVar.sellingCostRaw = (rawVar.gainsTaxRaw + rawVar.realEstateFeeAmountRaw);
    return Math.round(rawVar.sellingCostRaw).toLocaleString();
  }),
  netBuyAmount: computed(() => {
    rawVar.netBuyRaw = (rawVar.initTotalRaw + rawVar.recurringTotalRaw - rawVar.equityRaw + rawVar.sellingCostRaw);
    return Math.round(rawVar.netBuyRaw).toLocaleString();
  }),
  netRentAmount: computed(() => {
    rawVar.netRentRaw = (rawVar.totalRentPaidRaw - rawVar.investDownRaw - rawVar.investRecurDeltaRaw);
    return Math.round(rawVar.netRentRaw).toLocaleString();
  }),
  totalInvestAmount: computed(() => {
    return Math.round(rawVar.investDownRaw + rawVar.investRecurDeltaRaw).toLocaleString();
  }),

  equivRent: computed(() => {
    var rent = 0;
    var netRent = 0;
    if (rawVar.netBuyRaw > 100000000) return "NaN";

    while (netRent / rawVar.netBuyRaw < 0.99) {
      rent = rent + Math.min(1000, (rawVar.netBuyRaw - netRent) / 1000);

      var x = 0;
      var currentYearRent = rent;
      for (var i = 0; i < comVar.yearsTotalCom; i++) {
        x = x + currentYearRent * 12;
        currentYearRent = currentYearRent * (1 + Number(comVar.rentRateCom) / 100);
      }
      var totalRent = x;

      var x = rawVar.downOwnRaw + rawVar.upfrontCostsRaw;
      for (var i = 0; i < comVar.yearsTotalCom; i++) {
        x = x * (1 + Number(comVar.investCom) / 100);
      }
      var invDown = x;

      var x = 0;
      var currentYearRent = rent;
      for (var i = 0; i < comVar.yearsTotalCom; i++) {
        if (i < comVar.secondLengthCom) {
          var diffCost = comVar.recurringYearlyCostBeforeSecondDone - (currentYearRent * 12);
        } else {
          var diffCost = comVar.recurringYearlyCostAfterSecondDone - (currentYearRent * 12);
        }
        x = x + diffCost;
        x = x * (1 + Number(comVar.investCom) / 100);
        currentYearRent = currentYearRent * (1 + Number(comVar.rentRateCom) / 100);
      }
      var invRecur = x;

      netRent = totalRent - invDown - invRecur;
    }
    return Math.round(rent).toLocaleString();

  }),
  equivPurchase: computed(() => {

    var price = 0;
    var netBuy = 0;
    var totalRentPaidRaw = rawVar.totalRentPaidRaw;
    if (totalRentPaidRaw > 100000000) return "NaN";
    var netRent = totalRentPaidRaw;
    var equiv = 0;

    while (netBuy / netRent < 0.99) {
      price = price + Math.min(100000, (netRent - netBuy) / 10);

      var downOwnRaw = (comVar.downOwnInputCom / 100 * price);
      var downSecondRaw = (comVar.downSecondInputCom / 100 * price);
      var downTotalRaw = downOwnRaw + downSecondRaw;
      var upfrontCostsRaw = (comVar.upfrontCostsInputCom / 100 * price);

      var initTotalRaw = downOwnRaw + downSecondRaw + upfrontCostsRaw;

      if (initVar.maintInput < 0 || initVar.maintInput > 20) {
        var maintRaw = (0.75 / 100 * price)
      }
      else {
        var maintRaw = (initVar.maintInput / 100 * price);
      }

      var initialMortgageRaw = (price - downOwnRaw - downSecondRaw);
      var initialFirstRaw = Math.min(initialMortgageRaw, price * 0.67)
      var firstInterestRaw = (comVar.mortgageRateCom / 100 * initialFirstRaw);

      var initialSecondRaw = (Math.max(initialMortgageRaw - initialFirstRaw, 0));
      var secondInterestRaw = ((comVar.mortgageRateCom + comVar.secondPremiumCom) / 100 * initialSecondRaw);

      var x = initVar.eigenInput;
      if (x < 0 || x > 100) {
        var eigenRaw = 0;
      } else {
        var eigenRaw = (initVar.eigenInput / 100 * .0425 * price);
      }
      var secondAmortisationRaw = (initialSecondRaw / comVar.secondLengthCom);

      var x = initVar.marginalInput;
      if (x < 0 || x >= 100) { var marginalRaw = 0; var marginalOnlyFirstRaw = 0; }
      else {
        var marginalOnlyFirstRaw = (initVar.marginalInput / 100 * (eigenRaw - maintRaw - firstInterestRaw));
        var marginalRaw = (initVar.marginalInput / 100 * (eigenRaw - maintRaw - firstInterestRaw - secondInterestRaw));
      }

      if (initVar.propTaxInput < 0 || initVar.propTaxInput > 20) { var propTaxRaw = 0; } else { var propTaxRaw = (initVar.propTaxInput / 100 * price); }



      var recurringYearlyCostBeforeSecondDone = (maintRaw + secondAmortisationRaw + secondInterestRaw + firstInterestRaw + marginalRaw + propTaxRaw);
      var recurringYearlyCostAfterSecondDone = (firstInterestRaw + maintRaw + marginalOnlyFirstRaw + propTaxRaw);

      if (comVar.yearsTotalCom > comVar.secondLengthCom) {
        var recurringTotalRaw = comVar.secondLengthCom * recurringYearlyCostBeforeSecondDone + (comVar.yearsTotalCom - comVar.secondLengthCom) * recurringYearlyCostAfterSecondDone;
      } else {
        var recurringTotalRaw = comVar.yearsTotalCom * recurringYearlyCostBeforeSecondDone;
      }

      var salePriceRaw = Math.round((price * ((comVar.houseRateCom / 100 + 1) ** comVar.yearsTotalCom)));
      var totalGainRaw = salePriceRaw - price;
      var equityRaw = (totalGainRaw + downTotalRaw + Math.min(initVar.secondMortgageAmortizationLength, comVar.yearsTotalCom) * secondAmortisationRaw);

      var sellingCostRaw = totalGainRaw * (initVar.gainsTaxInput / 100) + salePriceRaw * (initVar.realEstateFeeInput / 100);

      netBuy = (initTotalRaw + recurringTotalRaw - equityRaw + sellingCostRaw);
      var netBuytest = (rawVar.initTotalRaw + rawVar.recurringTotalRaw - rawVar.equityRaw + rawVar.sellingCostRaw);



      var rentRaw = parseInt(initVar.rentInput.toString().replace(/,/g, ''), 10);

      var x = downOwnRaw + upfrontCostsRaw;
      for (var i = 0; i < comVar.yearsTotalCom; i++) {
        x = x * (1 + Number(comVar.investCom) / 100);
      }
      var invDown = x;

      var x = 0;
      var currentYearRent = rentRaw;
      for (var i = 0; i < comVar.yearsTotalCom; i++) {
        if (i < comVar.secondLengthCom) {
          var diffCost = recurringYearlyCostBeforeSecondDone - (currentYearRent * 12);
        } else {
          var diffCost = recurringYearlyCostAfterSecondDone - (currentYearRent * 12);
        }
        x = x + diffCost;
        x = x * (1 + Number(comVar.investCom) / 100);
        currentYearRent = currentYearRent * (1 + Number(comVar.rentRateCom) / 100);
      }
      var invRecur = x;


      netRent = totalRentPaidRaw - invDown - invRecur;
      equiv = price;
    }

    return Math.round(equiv).toLocaleString();
  })
})

const initVarFix = {
  priceInput: 1000000,
  rentInput: 3000,
  downOwnInput: 10,
  downSecondInput: 10,
  mortgageRateInput: 2.5,
  secondMortgageAmortizationLength: 15,
  yearsInProperty: 15,
  upfrontCostsInput: 0.5,
  maintInput: 0.75,
  marginalInput: 35,
  eigenInput: 70,
  propTaxInput: 0,
  investInput: 7,
  houseRateInput: 1.25,
  rentRateInput: 1.5,
  secondPremiumInput: 1,
  gainsTaxInput: 25,
  realEstateFeeInput: 4
};

var initVar = reactive({ ...initVarFix });



function reset() {
  Object.assign(initVar, initVarFix);
  history.pushState({}, "", document.location.origin);
}

const showMortgage = reactive({ value: false });
const showAnnual = reactive({ value: false });
const showAssumptions = reactive({ value: false });
const showTaxesFees = reactive({ value: false });
const showMiniDrawer = reactive({ value: false });
const showDown = reactive({
  value: false,

  text: computed(() => {
    if (!showDown.value) {
      return "Expand to edit details"
    }
    else { return "Collapse" }
  })
});

function loadState(idOfClicked: string) {

  let foundState = saveStates.list.find(x => x.id === idOfClicked);
  if (!foundState) { return; }
  Object.assign(initVar, foundState.initVar);
  // Object.assign(comVar, foundState.comVar);
  Object.assign(rawVar, foundState.rawVar);
  history.pushState({}, "", document.location.origin + "/" + foundState.id);

  // console.log("save states: ");
  // console.log(saveStates.list);
}

function removeState(idOfClicked: string) {

  var removeIndex = saveStates.list.map(item => item.id).indexOf(idOfClicked);
  ~removeIndex && saveStates.list.splice(removeIndex, 1);

}

var floor=Math.floor, abs=Math.abs, log=Math.log, round=Math.round, min=Math.min;
var abbrev = ['K', 'M', 'B']; // abbreviations in steps of 1000x; extensible if need to edit

function rnd(n:any, precision:any) {
    var prec = 10**precision;
    return round(n*prec)/prec;
}

function formatNum(n:any) {
    n = parseFloat(n.replace(/,/g, ''));
    var base = floor(log(abs(n))/log(1000));
    var suffix = abbrev[min(abbrev.length-1, base-1)];
    base = abbrev.indexOf(suffix) + 1;
    return suffix ? rnd(n/1000**base,2)+suffix : ''+n;
}

const currOptions =
// // Not using the maska example money format since it also fails the '1,000,000 -> 100,000 -> 1,200,000' second number switch test
// {
//   preProcess: val => val.replace(/[$,]/g, ''),
//   postProcess: val => {
//     if (!val) return ''

//     const sub = 3 - (val.includes('.') ? val.length - val.indexOf('.') : 0)

//     return Intl.NumberFormat('en-US', {
//       style: 'currency',
//       currency: 'USD'
//     }).format(val)
//       .slice(0, sub ? -sub : undefined)
//   }
// }
{
  mask: ["##,###,###", "#,###,###", "#,##,###", "###,###", "##,###", "#,###", "###", "##", "#"], reverse: false, eager: false
};
</script>

<template>
  <v-div v-if="!isFetching.value">
    <v-container>
      <!-- <v-app-bar scroll-behavior="hide"> -->
      <v-row>
        <v-col class="mx-2">
      <v-toolbar class="ma-0" scroll-behavior="hide" color="grey-darken-4">
        <v-btn icon="mdi-content-save" @click="hash"></v-btn>

        <v-menu :close-on-content-click="false">
      <template v-slot:activator="{ props }">
        <v-btn
          color="secondary"
          :variant="saveListBlink.value"
          v-bind="props"
          class="mx-2"
        >
          Saved Analyses
        </v-btn>
      </template>
      <v-list>
        <v-list-item v-if="saveStates.list.length < 1">
          <v-row class="px-2 ma-0">
                <v-card-text class="align-self-center text-caption pa-0">No Saved Analyses</v-card-text>
          </v-row>
         </v-list-item>
        <v-list-item
          v-for="saveState in saveStates.list"
          :key="saveState.id"
        >
        <v-card variant="outlined" bg-color="blue" class="pa-0 mx-2" @click="loadState(saveState.id)">
          <v-row class="px-2 ma-0">
                <v-card-text class="align-self-center text-caption pa-0"> {{ saveStates.list.indexOf(saveState) + 1}} : {{ formatNum(saveState.text1) }} Buy / {{ formatNum(saveState.text2) }} Rent</v-card-text>
              <v-btn size="x-small" class="pa-0 ml-1 align-self-center" icon="mdi-close" @click="removeState(saveState.id)"> </v-btn>
          </v-row>
        </v-card>
          <!-- <v-list-item-title>{{ saveState.text1 }}</v-list-item-title> -->
        </v-list-item>
      </v-list>
    </v-menu> 
        <!-- <v-card variant="outlined" bg-color="blue" class="pa-0 mx-2" :key="saveState.id" v-for="saveState in saveStates.list"
          @click="loadState(saveState.id)">
          <v-row class="px-2 ma-0">
                <v-card-text class="align-self-center text-caption pa-0">{{ formatNum(saveState.text1) }} Buy / {{ formatNum(saveState.text2) }} Rent</v-card-text>
              <v-btn size="x-small" class="pa-0 ml-1 align-self-center" icon="mdi-close" @click="removeState(saveState.id)"> </v-btn>
          </v-row>
        </v-card> -->

        <v-spacer></v-spacer>
        <v-btn class="mr-4" variant="outlined" @click="reset">Reset</v-btn>
      </v-toolbar>
    </v-col>
    </v-row>
      <!-- </v-app-bar> -->

      <v-row> <v-col align="center" class="ma-0 pa-0">
          <div class="text-h5 ma-4"> Rent vs. Buy, Switzerland </div>
        </v-col></v-row>
      <v-row>
        <v-col>
          <v-card class="mx-2 px-4">
            <v-card-title>
              <span class="text-body-2 text-sm-h6">
                Property Purchase Price vs. Property Rent
              </span>
            </v-card-title>
            <v-row class="pt-2"> <v-col cols="12" sm="6"> <v-text-field base-color="cyan-accent-2" clearable
                  label="Enter Purchase Price" variant="outlined" v-maska:[currOptions] v-model="initVar.priceInput"
                  suffix="CHF"></v-text-field>
              </v-col>
              <v-col cols="12" sm="6"> <v-text-field clearable base-color="cyan-accent-2" label="Enter Rent Per Month"
                  variant="outlined" v-maska:[currOptions] v-model="initVar.rentInput" suffix='CHF'></v-text-field>
              </v-col>
            </v-row>
          </v-card>

          <v-card class="ma-2 px-4">
            <v-card-title>
              <span class="text-body-2 text-sm-h6">
                Total Years Living In Property (vs. Renting)
              </span></v-card-title>
            <v-card-text class="text-medium-emphasis text-caption">
              Generally speaking, renting is more advantageous over a shorter timeframe, because the cost benefits of
              purchasing take a
              longer time to outweigh the cost negatives of purchasing.
            </v-card-text>
            <v-row>
              <v-col> <v-text-field base-color="cyan-accent-2" label="" variant="outlined" suffix="years"
                  v-model="initVar.yearsInProperty" :rules="[rules.yearsInProperty]"></v-text-field> </v-col>
              <!-- <v-col> <v-card text="The upfront costs
              of buying are better spread out over many years"></v-card> </v-col> -->
            </v-row>
          </v-card>

          <v-form ref="form" validate-on="input" class="ma-2">
            <v-card class="pa-2">
              <v-row> <v-col align="start" align-self="start"> <v-card-title>
                    <span class="text-body-1 text-sm-h6">
                      Initial Costs </span></v-card-title> </v-col>
                <v-col class="mt-1" align="end" align-self="center">

                  <v-btn class="text-body-2 text-sm-h6" variant="text"
                    :append-icon="showDown.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                    @click="showDown.value = !showDown.value"> {{ showDown.text }} </v-btn>
                </v-col>
              </v-row>
              <v-expand-transition>
                <div v-show="showDown.value">
                  <v-card-text class="text-caption text-medium-emphasis">
                    While the second pillar amount can be withdrawn to contribute to the down payment, at least 10% of the
                    down
                    payment must be made with own funds (liquid cash + 3rd pillar)
                    , and total down payment must be at least 20% of the purchase price.
                  </v-card-text>
                  <v-row> <v-col cols="12" sm="6"> <v-text-field base-color="cyan-accent-2" clearable
                        label="% Down from Own Funds + 3rd Pillar" variant="outlined" v-model="initVar.downOwnInput"
                        suffix="%" :rules="[rules.downOwn]"></v-text-field> </v-col>
                    <v-col cols="12" sm="6"> <v-text-field readonly label="Own Funds Down Amount" variant="outlined"
                        v-model="comVar.downOwnDisplay"></v-text-field> </v-col> </v-row>
                  <v-row class="mb-0"> <v-col class="py-0" cols="12" sm="6"> <v-text-field base-color="cyan-accent-2"
                        clearable label="% Down from 2nd Pillar" variant="outlined" v-model="initVar.downSecondInput"
                        suffix="%" :rules="[rules.down]"></v-text-field> </v-col>
                    <v-col class="py-0" cols="12" sm="6"> <v-text-field readonly label="2nd Pillar Down Amount"
                        variant="outlined" v-model="comVar.downSecondDisplay" persistent-hint
                        hint="Total withdrawal of second pillar account only possible up to age 50"></v-text-field>
                    </v-col> </v-row>
                  <v-row class="mx-2 mb-5 mt-2">
                    <p class="text-caption text-medium-emphasis">Generally second pillar 'investment' has a very low
                      growth/interest rate, so this analysis excludes the '2nd Pillar Down Amount' from the 'Investment
                      Returns' calculated later.</p>
                  </v-row>
                  <v-row class="mb-4"> <v-col cols="12" sm="6"> <v-text-field base-color="cyan-accent-2" clearable
                        label="Other Costs as % of Price" persistent-hint hint="Notary fees, property transfer tax, etc"
                        variant="outlined" v-model="initVar.upfrontCostsInput" suffix="%"
                        :rules="[rules.posrate]"></v-text-field> </v-col>
                    <v-col cols="12" sm="6"> <v-text-field readonly label="Upfront Costs Amount" variant="outlined"
                        v-model="comVar.upfrontCostsAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
                </div>
              </v-expand-transition>
              <v-row> <v-col cols="12" sm="6"> <v-text-field readonly label="Percent Down Payment Total"
                    variant="outlined" v-model="comVar.downTotalInput" suffix="%" :rules="[rules.down]"></v-text-field>
                </v-col>

                <v-col cols="12" sm="6"> <v-text-field readonly label="Down Payment Total Amount" variant="outlined"
                    v-model="comVar.downTotalDisplay"></v-text-field> </v-col> </v-row>
            </v-card>
          </v-form>

          <v-card class="ma-2 pa-2">
            <v-row> <v-col> <v-card-title>
                  <span class="text-body-1 text-sm-h6">
                    Mortgage Details </span></v-card-title> </v-col>
              <v-col align="right">
                <v-btn :icon="showMortgage.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                  @click="showMortgage.value = !showMortgage.value"></v-btn>
              </v-col>
            </v-row>
            <v-row class="mb-0"> <v-col class="py-0"> <v-card text="Mortgage Interest Rate"></v-card> </v-col>
              <v-col class="py-0"> <v-text-field base-color="cyan-accent-2" label="(Assumed avg. rate)" variant="outlined"
                  v-model="initVar.mortgageRateInput" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
            </v-row>

            <v-expand-transition>
              <div v-show="showMortgage.value">

                <v-row class="mt-2"> <v-col> <v-card text="Years to Second Mortgage Amortisation"></v-card> </v-col>
                  <v-col> <v-text-field base-color="cyan-accent-2" variant="outlined" label="Max 15 years by law"
                      :rules="[rules.second]" v-model="initVar.secondMortgageAmortizationLength"></v-text-field> </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card text="Total Initial Mortgaged Amount"></v-card> </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.initialMortgagedAmount"></v-text-field>
                  </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card
                      text="Total First Mortgage amount (max 67% of purchase price)"></v-card> </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.initialFirstAmount"></v-text-field>
                  </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card text="First Mortgage, Interest per Year"></v-card>
                  </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.firstInterest"></v-text-field>
                  </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card
                      text="Total Second Mortgage amount (max 13% of purchase price)"></v-card> </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.initialSecondAmount"></v-text-field>
                  </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card text="Second Mortgage, Amortisation per Year"></v-card>
                  </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.secondAmortisation"></v-text-field>
                  </v-col>
                </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">The second mortgage typically carries a premium of
                    0.5-1%
                    above the first mortgage interest rate. </p>
                </v-row>
                <v-row>
                  <v-col class="pb-0" cols="12" sm="6"> <v-text-field clearable base-color="cyan-accent-2"
                      label="% Premium" variant="outlined" v-model="initVar.secondPremiumInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field> </v-col>
                  <!-- <v-col> <v-card text="Second Mortgage, Interest per Year"></v-card> </v-col> -->
                  <v-col class="pb-0" cols="12" sm="6"> <v-text-field readonly label="Second Mortgage, Interest per Year"
                      variant="outlined" v-model="comVar.secondInterest"></v-text-field> </v-col>
                </v-row>
                <v-row class="mb-0"> <v-col class="py-0"> <v-card text="Total First Mortgage Monthly Payments"></v-card>
                  </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.firstMonthly"></v-text-field> </v-col>
                </v-row>

                <v-row class="my-0"> <v-col> <v-card text="Total Second Mortgage Monthly Payments"></v-card> </v-col>
                  <v-col> <v-text-field readonly variant="outlined" v-model="comVar.secondMonthly"></v-text-field>
                  </v-col>
                </v-row>
              </div>
            </v-expand-transition>
          </v-card>

          <v-card class="ma-2 pa-2">
            <v-row> <v-col> <v-card-title>
                  <span class="text-body-1 text-sm-h6">
                    Annual Non-Mortgage Costs
                  </span></v-card-title> </v-col>
              <v-col align="right">
                <v-btn :icon="showAnnual.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                  @click="showAnnual.value = !showAnnual.value"></v-btn>
              </v-col>
            </v-row>
            <v-expand-transition>
              <div v-show="showAnnual.value">
                <v-row class="mt-2 mb-0">
                  <p class="mx-4 mb-4 text-medium-emphasis text-caption"> Annual recurring costs include taxes,
                    maintenance,
                    insurance, etc. </p>
                </v-row>
                <v-row class="mt-0">
                  <p class="pt-2 mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis"> Maintenance</span> per year is usually
                    between
                    0.5 and 1% of purchase price </p>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="cyan-accent-2" clearable label="% of Purchase Price"
                      variant="outlined" v-model="initVar.maintInput" suffix="%" :rules="[rules.posrate]"></v-text-field>
                  </v-col>
                  <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined"
                      v-model="comVar.maintAmount" suffix="CHF"></v-text-field> </v-col> </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">
                    <span class="font-weight-bold text-body-2 text-high-emphasis">Inputed rental value, </span>
                    or Eigenmietwert, is counted as
                    additional income for personal taxes.
                    However, mortgage interest and maintenance can be deducted in order to offset this additional income.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field base-color="cyan-accent-2" clearable
                      label="Marginal Income Tax Rate" variant="outlined" v-model="initVar.marginalInput" suffix="%"
                      :rules="[rules.numberIn100]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Extra Income Tax Per Year" persistent-hint
                      hint="(1st+2nd Mortgages)" variant="outlined" v-model="comVar.marginalAmount"
                      suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly persistent-hint hint="(1st Mortgage Only)"
                      variant="outlined" v-model="comVar.marginalOnlyFirstAmount" suffix="CHF"></v-text-field> </v-col>
                </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">
                    <span class="font-weight-bold text-body-2 text-high-emphasis">Eigenmietwert </span>
                    is often calculated from a fraction of the actual purchase price.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field base-color="cyan-accent-2" clearable
                      label="Eigenmietwert Value" persistent-hint hint="(as % of Price)" variant="outlined"
                      v-model="initVar.eigenInput" suffix="%" :rules="[rules.numberIn100]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Eigenmietwert" variant="outlined"
                      v-model="comVar.eigenValue" suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Eigenmietwert 'Income'" variant="outlined"
                      persistent-hint hint="(per year)" v-model="comVar.eigenAmount" suffix="CHF"></v-text-field> </v-col>
                </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">
                    <span class="font-weight-bold text-body-2 text-high-emphasis">Property Tax</span>
                    only exists in some cantons, and is levied at a percentage of the purchase price.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="6"> <v-text-field base-color="cyan-accent-2" clearable
                      label="% of Purchase Price, Per Year" variant="outlined" v-model="initVar.propTaxInput" suffix="%"
                      :rules="[rules.posrate]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="6"> <v-text-field readonly label="Property Tax Per Year" variant="outlined"
                      v-model="comVar.propTaxAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
              </div>
            </v-expand-transition>
          </v-card>

          <v-card class="ma-2 pa-2">
            <v-row> <v-col> <v-card-title>
                  <span class="text-body-1 text-sm-h6">
                    Assumptions for the Future
                  </span></v-card-title> </v-col>
              <v-col align="right">
                <v-btn :icon="showAssumptions.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                  @click="showAssumptions.value = !showAssumptions.value"></v-btn>
              </v-col>
            </v-row>
            <v-expand-transition>
              <div v-show="showAssumptions.value">
                <v-row class="mt-2">
                  <p class="mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Average Investment Return Rate</span>
                    not accounting for inflation is around 9% for global equities over the last century, but lower for
                    various
                    fixed-income portfolios.
                    For an accurate comparison, this value should be adjusted to reflect post-tax
                    gains (i.e. dividend income tax, capital gains tax in some limited circumstances). All additional
                    money
                    saved via differences in initial or recurring costs are assumed to be invested and growing
                    at the rate set below.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="6"> <v-text-field base-color="cyan-accent-2" clearable
                      label="Return Rate, Per Year" variant="outlined" v-model="initVar.investInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="6"> <v-text-field readonly label="Extra Profit from Investing" persistent-hint
                      hint="(Extra money if you rent vs buy)" variant="outlined" v-model="comVar.totalInvestAmount"
                      suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Property Price Growth Rate</span> is
                    typically
                    1-1.5% in urban areas of Switzerland over the last 50 years</p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field base-color="cyan-accent-2" clearable
                      label="Growth Rate, Per Year" variant="outlined" v-model="initVar.houseRateInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Final Property Value" variant="outlined"
                      v-model="comVar.salePrice" suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Total Property Gain" variant="outlined"
                      v-model="comVar.totalGain" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Rental Price Growth Rate</span> is typically
                    coupled to both property price growth rates and interest rates, but can differ over time</p>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="cyan-accent-2" clearable label="Growth Rate, Per Year"
                      variant="outlined" v-model="initVar.rentRateInput" suffix="%" :rules="[rules.rate]"></v-text-field>
                  </v-col>
                  <v-col> <v-text-field readonly label="Final Monthly Rent" hint="(In Final Year Of Analysis)"
                      persistent-hint variant="outlined" v-model="comVar.finalRent" suffix="CHF"></v-text-field> </v-col>
                </v-row>
              </div>
            </v-expand-transition>
          </v-card>

          <v-card class="ma-2 pa-2">
            <v-row> <v-col> <v-card-title>
                  <span class="text-body-1 text-sm-h6">
                    Sale Taxes and Fees
                  </span> </v-card-title> </v-col>
              <v-col align="right">
                <v-btn :icon="showTaxesFees.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                  @click="showTaxesFees.value = !showTaxesFees.value"></v-btn>
              </v-col>
            </v-row>
            <v-expand-transition>
              <div v-show="showTaxesFees.value">
                <v-row class="mt-2">
                </v-row>
                <v-row>
                  <p class="mx-4 my-2 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Real Estate Sale Fees</span> are generally
                    around
                    4% of the sale price in most of Switzerland</p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field base-color="cyan-accent-2" clearable
                      label="% of Sale Price" variant="outlined" v-model="initVar.realEstateFeeInput" suffix="%"
                      :rules="[rules.posrate]"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Sale Price" variant="outlined"
                      v-model="comVar.salePrice" suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Sale Fee" variant="outlined"
                      v-model="comVar.realEstateFeeAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Property Capital Gains Tax Rate </span>
                    differs
                    by
                    canton and by how long is spent living in the property - typically, the longer you stay, the less
                    taxes
                    are
                    owed.</p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field base-color="cyan-accent-2" clearable label="Tax Rate"
                      variant="outlined" persistent-hint hint="(% of Gains As Tax)" v-model="initVar.gainsTaxInput"
                      suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Capital Gain" variant="outlined"
                      v-model="comVar.totalGain" suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Tax Paid" variant="outlined"
                      v-model="comVar.gainsTaxAmount" suffix="CHF"></v-text-field> </v-col>
                </v-row>
              </div>
            </v-expand-transition>
          </v-card>

        </v-col>

        <div v-if=mdAndUp>
          <v-navigation-drawer permanent :width="md ? 400 : 500" class="pa-4" location="right">
            <v-row>
              <v-col>
                <v-row>
                  <v-col>
                    <p class="mx-4 text-high-emphasis text-h5">Buying Costs</p>
                  </v-col>
                  <v-col>
                    <p class="mx-4 text-high-emphasis text-h5">Renting Costs</p>
                  </v-col>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Initial Costs, Buy"
                      variant="outlined" persistent-hint hint="(Including Down Payment)" v-model="comVar.initTotal"
                      suffix="CHF"></v-text-field> </v-col>
                  <v-col> <v-text-field base-color="red-accent-1" readonly label="Total Rent Paid" variant="outlined"
                      v-model="comVar.totalRentPaid" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Recurring Costs, Buy"
                      variant="outlined" v-model="comVar.recurringTotal" suffix="CHF"></v-text-field> </v-col>
                  <v-col> <v-text-field :base-color="comVar.investDownSign" readonly label="Investment Returns"
                      persistent-hint hint="From Initial Costs" variant="outlined" v-model="comVar.investDown"
                      suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="green-accent-2" readonly label="Equity (Value Owned)"
                      variant="outlined" persistent-hint hint="(Down + Gains)" v-model="comVar.equity"
                      suffix="CHF"></v-text-field> </v-col>
                  <v-col> <v-text-field :base-color="comVar.investRecurSign" readonly label="Investment Returns"
                      persistent-hint hint="From Recurring Costs Delta" variant="outlined"
                      v-model="comVar.investRecurDelta" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Selling Costs" variant="outlined"
                      v-model="comVar.sellingCostAmount" suffix="CHF"></v-text-field> </v-col>
                  <v-col></v-col>

                </v-row>
                <v-divider :thickness="4" class="border-opacity-50 mb-2"> </v-divider>
                <v-card-text class="py-0 text-high-emphasis text-subtitle-1">Net Costs, Buying vs. Renting after
                  {{ comVar.yearsTotalCom }} Years</v-card-text>
                <v-card-text class="mb-2 text-medium-emphasis text-caption">A simple way to visualize this number is: if
                  you started with 10,000,000 CHF in your account on Day 0, and the account only had inflows and
                  outflows corresponding to the numbers here (i.e. no salary, no expenses on food, travel, etc.), how
                  much less (or more) would you have in your account after {{ comVar.yearsTotalCom }} years?
                </v-card-text>
                <v-row> <v-col> <v-text-field :base-color="comVar.netBuySign" readonly label="Net Cost, Buying"
                      variant="outlined" v-model="comVar.netBuyAmount" suffix="CHF"></v-text-field> </v-col>

                  <v-col> <v-text-field :base-color="comVar.netRentSign" readonly label="Net Cost, Renting"
                      variant="outlined" v-model="comVar.netRentAmount" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-divider :thickness="4" class="border-opacity-50 mb-4"> </v-divider>
                <v-row> <v-col>

                    <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                      <span class="text-high-emphasis"> {{ comVar.priceDisplay }} CHF</span>
                      purchase with these assumptions, if you could find an equivalent rental cheaper than approx.
                      <br>
                      <span class="text-high-emphasis"> {{ comVar.equivRent }} CHF</span>
                      <span class="text-medium-emphasis"> it would make more sense to rent.</span>
                    </v-card-text>
                  </v-col>
                  <v-col>
                    <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                      <span class="text-high-emphasis"> {{ initVar.rentInput }} CHF per month</span>
                      rental with these assumptions, if you could find an equivalent purchase cheaper than approx.
                      <br>
                      <span class="text-high-emphasis"> {{ comVar.equivPurchase }} CHF</span>
                      <span class="text-medium-emphasis"> it would make more sense to purchase.</span>
                    </v-card-text>
                  </v-col>
                </v-row>
              </v-col>
            </v-row>
          </v-navigation-drawer>
        </div>

        <div v-if=smAndDown>
          <v-navigation-drawer permanent class="py-2 pl-4 pr-4" :width="showMiniDrawer.value ? 250 : 75" touchless
            location="bottom">
            <v-row>
              <v-col>
                <v-row class="align-self-start"> <v-col class="ma-0 mt-1 px-2 align-self-center">
                    <v-card-text cols="10" class="py-0 text-high-emphasis text-body-2 align-self-center">Net Costs after
                      {{ comVar.yearsTotalCom }} Years</v-card-text>
                  </v-col>
                  <v-col cols="2" class="pa-2 mt-1 align-self-center">
                    <v-btn class="align-self-center" :icon="showMiniDrawer.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                      @click="showMiniDrawer.value = !showMiniDrawer.value"></v-btn>
                  </v-col>
                </v-row>

                <v-expand-transition>

                  <div v-show="showMiniDrawer.value">

                    <v-row class="mt-2"> <v-col> <v-text-field :base-color="comVar.netBuySign" readonly
                          label="Net Cost, Buying" variant="outlined" v-model="comVar.netBuyAmount"
                          suffix="CHF"></v-text-field> </v-col>

                      <v-col> <v-text-field :base-color="comVar.netRentSign" readonly label="Net Cost, Renting"
                          variant="outlined" v-model="comVar.netRentAmount" suffix="CHF"></v-text-field> </v-col>
                    </v-row>


                    <v-card-text class="mb-2 mt-0 pa-0 pb-2 text-medium-emphasis text-caption">A simple way to visualize
                      this number is: if
                      you started with 10,000,000 CHF in your account on Day 0, and the account only had inflows and
                      outflows corresponding to the numbers here (i.e. no salary, no expenses on food, travel, etc.), how
                      much less (or more) would you have in your account after {{ comVar.yearsTotalCom }} years?
                    </v-card-text>

                    <v-divider :thickness="4" class="border-opacity-50 mb-2"> </v-divider>
                    <v-row>
                      <v-col>
                        <p class="mx-4 text-high-emphasis text-subtitle-1">Buying Costs</p>
                      </v-col>
                      <v-col>
                        <p class="mx-4 text-high-emphasis text-subtitle-1">Renting Costs</p>
                      </v-col>
                    </v-row>
                    <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Initial Costs, Buy"
                          variant="outlined" persistent-hint hint="(Including Down Payment)" v-model="comVar.initTotal"
                          suffix="CHF"></v-text-field> </v-col>
                      <v-col> <v-text-field base-color="red-accent-1" readonly label="Total Rent Paid" variant="outlined"
                          v-model="comVar.totalRentPaid" suffix="CHF"></v-text-field> </v-col>
                    </v-row>
                    <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Recurring Costs, Buy"
                          variant="outlined" v-model="comVar.recurringTotal" suffix="CHF"></v-text-field> </v-col>
                      <v-col> <v-text-field :base-color="comVar.investDownSign" readonly label="Investment Returns"
                          persistent-hint hint="From Initial Costs" variant="outlined" v-model="comVar.investDown"
                          suffix="CHF"></v-text-field> </v-col>
                    </v-row>
                    <v-row> <v-col> <v-text-field base-color="green-accent-2" readonly label="Equity (Value Owned)"
                          variant="outlined" persistent-hint hint="(Down + Gains)" v-model="comVar.equity"
                          suffix="CHF"></v-text-field> </v-col>
                      <v-col> <v-text-field :base-color="comVar.investRecurSign" readonly label="Investment Returns"
                          persistent-hint hint="From Recurring Costs Delta" variant="outlined"
                          v-model="comVar.investRecurDelta" suffix="CHF"></v-text-field> </v-col>
                    </v-row>
                    <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Selling Costs"
                          variant="outlined" v-model="comVar.sellingCostAmount" suffix="CHF"></v-text-field> </v-col>
                      <v-col></v-col>

                    </v-row>

                    <v-row> <v-col>

                        <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                          <span class="text-high-emphasis"> {{ comVar.priceDisplay }} CHF</span>
                          purchase with these assumptions, if you could find an equivalent rental cheaper than approx.
                          <br>
                          <span class="text-high-emphasis"> {{ comVar.equivRent }} CHF</span>
                          <span class="text-medium-emphasis"> it would make more sense to rent.</span>
                        </v-card-text>
                      </v-col>
                      <v-col>
                        <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                          <span class="text-high-emphasis"> {{ initVar.rentInput }} CHF per month</span>
                          rental with these assumptions, if you could find an equivalent purchase cheaper than approx.
                          <br>
                          <span class="text-high-emphasis"> {{ comVar.equivPurchase }} CHF</span>
                          <span class="text-medium-emphasis"> it would make more sense to purchase.</span>
                        </v-card-text>
                      </v-col>
                    </v-row>
                  </div>
                </v-expand-transition>

              </v-col>
            </v-row>
          </v-navigation-drawer>
        </div>

      </v-row>


    </v-container>
  </v-div>
</template>
