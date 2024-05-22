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
  positiveIntegerOrZero: (value: number) => (Number.isInteger(Number(value)) && Number(value) > -1) || 'Value must be zero or a positive integer',
  yearsInProperty: (value: number) => (Number.isInteger(Number(value)) && Number(value) > 0 && Number(value) < 51) || 'Value must be a integer between 1 and 50 years',
  rate: (value: string) => (Number.isFinite(Number(value)) && Number(value) >= -50 && Number(value) <= 50 && value != "") || 'Value must be a number between -50 and 50',
  posrate: (value: string) => (Number.isFinite(Number(value)) && Number(value) >= 0 && Number(value) <= 20 && value != "") || 'Value must be a number between 0 and 20',
  numberIn100: (value: string) => (Number.isFinite(Number(value)) && value != "" && Number(value) >= 0 && Number(value) < 100) || 'Value must be a number between 0 and 100',
  firstAmortRule: (value: string) => (firstAmortInBounds) || 'Amounts entered are too large - Mortgage cannot be amortised over 100%!'
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
    history.pushState({}, "", document.location.origin + "/?id=" + hashVal)
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
  saveListBlink.value = "elevated";
  setTimeout(() => {
    saveListBlink.value = "outlined";
  }, 350);
}

window.onpopstate = function () {
  GetDynamoData();
}

const saveListBlink = reactive({ value: <"outlined" | "elevated">"outlined" });

// watch(saveStates, (newVal, oldVal) => {
//   newVal.list.forEach(function (state) {
//     console.log("for " + state.text + " rent raw:");
//     console.log(state.rawVar.rentRaw);
//   })
// })


const isFetching = reactive({ value: false });

const GetDynamoData = async () => {
  var link = document.location.href.split('/?id=');
  var id = link[1];
  if (id === "" || id === undefined) return;
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
    else { saveStates.list.push(saveStateNew); blinkList(); }

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
  equivBuyRaw: 0,
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
  totalTaxDifferenceRaw: 0,
  marginalOnlyFirstRaw: 0,
  eigenRaw: 0,
  eigenValue: 0,
  propTaxRaw: 0,
  initialFirstInterestRaw: 0,
  additionalFirstAmortisationRaw: 0,
  initialSecondInterestRaw: 0,
  secondAmortisationPerYearRaw: 0,
  cumulativeSecondAmortisation: 0,
  cumulativeFirstAmortisation: 0,
  initTotalRaw: 0,
  cumulativeRecurringYearlyCostsOfBuyingRaw: 0,
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
  netBuyProceedsRaw: 0,
  opportunityCostBuyingRaw: 0,
  opportunityCostRentingRaw: 0,
  // investRecurDeltaRaw: 0,
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
var firstAmortInBounds = true;

function RecurringCostCalculator(buyprice: number, rentprice: number, rentVsBuyComparisonCheck: boolean = true, netRentOrNetBuy: string = "netBuy") {
  var currentYearRecurringCost = 0;
  var cumulativeRecurringCostsForBuying = 0;

  var interest = Object.values(initVar.mortgageRateInput);
  var interest = interest.flatMap(i => [i, i, i, i, i]);

  var additionalAmort = Object.values(initVar.additionalFirstAmortisationPerMonth);
  var additionalAmort = additionalAmort.flatMap(i => [i, i, i, i, i]);

  var dOwn = (comVar.downOwnInputCom / 100 * buyprice);
  var dSecond = (comVar.downSecondInputCom / 100 * buyprice);
  var dTotal = (dOwn + dSecond);
  var dInitMortgage = (buyprice - dTotal);
  var dInitFirst = (Math.min(dInitMortgage, buyprice * 0.67));
  var dInitSecond = (Math.max(dInitMortgage - dInitFirst, 0));
  var eigRaw = (initVar.eigenInput / 100 * .0425 * buyprice);
  var maintRaw = (initVar.maintInput / 100 * buyprice);
  var sAmorPerYear = (dInitSecond / comVar.secondLengthCom);
  var propTaxRaw = (initVar.propTaxInput / 100 * buyprice);

  var uCosts = (comVar.upfrontCostsInputCom / 100 * buyprice);
  var iTotal = (dTotal + uCosts);

  if (!rentVsBuyComparisonCheck) {
    rawVar.downOwnRaw = dOwn;
    rawVar.downSecondRaw = dSecond;
    rawVar.downTotalRaw = dTotal;
    rawVar.initialMortgageRaw = dInitMortgage;
    rawVar.initialFirstRaw = dInitFirst;
    rawVar.initialSecondRaw = dInitSecond;
    rawVar.eigenRaw = eigRaw
    rawVar.maintRaw = maintRaw
    rawVar.secondAmortisationPerYearRaw = sAmorPerYear;
    rawVar.propTaxRaw = propTaxRaw;

    rawVar.upfrontCostsRaw = uCosts;
    rawVar.initTotalRaw = iTotal;
  }

  var firstAmountLeftToAmortise = dInitFirst;
  var secondAmountLeftToAmortise = dInitSecond;

  var firstInterestPaidInCurrentYear = 0;
  var secondInterestPaidInCurrentYear = 0;

  var totalTaxDifferencePaidInCurrentYear = 0;
  var totalTaxDifferenceCumulative = 0;

  var currentYearRent = rentprice;
  var diffInRecurringToBeInvested = 0;
  var recurringInvestmentDifferenceTotal = 0;

  var totalRentPaidCumulative = 0;
  var finalRent = 0;

  var initialBuyCostsInvestedInCaseOfRenting = dOwn + uCosts;
  var fAmorPerYear = 0;

  var ongoingBuyOpportunityCost = 0 + initialBuyCostsInvestedInCaseOfRenting;
  var ongoingRentOpportunityCost = 0;

  for (var i = 0; i < comVar.yearsTotalCom; i++) {

    //Update the interest and taxes so they can be added to the recurring costs of the current year
    firstInterestPaidInCurrentYear = (interest[i]) / 100 * firstAmountLeftToAmortise;
    secondInterestPaidInCurrentYear = (interest[i] + comVar.secondPremiumCom) / 100 * secondAmountLeftToAmortise;
    totalTaxDifferencePaidInCurrentYear = (initVar.marginalInput / 100 * (eigRaw - maintRaw - firstInterestPaidInCurrentYear - secondInterestPaidInCurrentYear));

    sAmorPerYear = Math.min(sAmorPerYear, secondAmountLeftToAmortise);
    fAmorPerYear = Math.min(additionalAmort[i] * 12, firstAmountLeftToAmortise);

    //Summing maintenance, interest, and tax recurring costs for the current year
    currentYearRecurringCost =

      maintRaw

      + firstInterestPaidInCurrentYear
      + secondInterestPaidInCurrentYear

      + sAmorPerYear
      + fAmorPerYear

      + totalTaxDifferencePaidInCurrentYear

      + propTaxRaw;

    ongoingBuyOpportunityCost = (ongoingBuyOpportunityCost + currentYearRecurringCost) * (1 + Number(comVar.investCom) / 100);

    //Keeping track of the cumulative recurring cost
    cumulativeRecurringCostsForBuying = cumulativeRecurringCostsForBuying + currentYearRecurringCost;

    //Investing the differential in current cost, and growing that investment amount

    // Not using these, switching to opportunity costs
    // diffInRecurringToBeInvested = currentYearRecurringCost - currentYearRent * 12;
    // recurringInvestmentDifferenceTotal = (recurringInvestmentDifferenceTotal*(1 + Number(comVar.investCom) / 100)) + diffInRecurringToBeInvested;

    ongoingRentOpportunityCost = (ongoingRentOpportunityCost + currentYearRent * 12) * (1 + Number(comVar.investCom) / 100);

    //Keeping track of the total difference in tax paid, total rent paid
    totalTaxDifferenceCumulative = totalTaxDifferenceCumulative + totalTaxDifferencePaidInCurrentYear;
    totalRentPaidCumulative = totalRentPaidCumulative + currentYearRent * 12;

    //Updating the rental cost and amortisation left (for calcuating interest) for the next year
    currentYearRent = currentYearRent * (1 + Number(comVar.rentRateCom) / 100);
    finalRent = currentYearRent;
    secondAmountLeftToAmortise = Math.max(secondAmountLeftToAmortise - sAmorPerYear, 0);
    firstAmountLeftToAmortise = Math.max(firstAmountLeftToAmortise - additionalAmort[i] * 12, 0);
  }


  if (!rentVsBuyComparisonCheck) {
    //  console.log("CHECK STARTS HERE:")
  //   console.log('first');
  //   console.log(Math.round(firstInterestPaidInCurrentYear));
  //   console.log('second');
  //   console.log(Math.round(secondInterestPaidInCurrentYear));
  //   console.log('maint');
  //   console.log(Math.round(maintRaw));
  //   console.log('amor1');
  //   console.log(Math.round(fAmorPerYear));
  //   console.log('amor2');
  //   console.log(Math.round(sAmorPerYear));
  //   console.log('tax');
  //   console.log(Math.round(totalTaxDifferencePaidInCurrentYear));
  //   console.log('this year');
  //   console.log(Math.round(currentYearRecurringCost));
    // console.log('Final investment, buy:');
    // console.log(Math.round(ongoingBuyOpportunityCost));
    // console.log(Math.round(cumulativeRecurringCostsForBuying));
    // console.log('Final initial investment:');
    // console.log(Math.round(initialBuyCostsInvestedInCaseOfRenting));
  }

  var ttD = totalTaxDifferenceCumulative / comVar.yearsTotalCom;
  var cFA = dInitFirst - firstAmountLeftToAmortise;
  var cSA = dInitSecond - secondAmountLeftToAmortise;
  // var iRDR = recurringInvestmentDifferenceTotal;
  var cRYC = cumulativeRecurringCostsForBuying;

  var sPriceRaw = Math.round((buyprice * ((comVar.houseRateCom / 100 + 1) ** comVar.yearsTotalCom)));
  var tGainRaw = sPriceRaw - buyprice;
  var eqRaw = tGainRaw + dTotal + cFA + cSA;

  var gainsTaxRaw = Math.round(tGainRaw * (initVar.gainsTaxInput / 100));
  var realEstateFeeAmountRaw = sPriceRaw * (initVar.realEstateFeeInput / 100);
  var sellCostRaw = (gainsTaxRaw + realEstateFeeAmountRaw);

  var opportunityCostBuyingRaw = ongoingBuyOpportunityCost - cumulativeRecurringCostsForBuying - initialBuyCostsInvestedInCaseOfRenting;
  var opportunityCostRentingRaw = ongoingRentOpportunityCost - totalRentPaidCumulative;

  var netBuyProceedsRaw = eqRaw - sellCostRaw;

  var netBuyRaw = (iTotal + cRYC + opportunityCostBuyingRaw - netBuyProceedsRaw);

  var totalRentPaidRaw = totalRentPaidCumulative;

  var investDownRaw = initialBuyCostsInvestedInCaseOfRenting;

  var netRentRaw = (totalRentPaidRaw + opportunityCostRentingRaw);

  if (!rentVsBuyComparisonCheck) {
    rawVar.totalTaxDifferenceRaw = ttD;
    rawVar.cumulativeFirstAmortisation = cFA;
    rawVar.cumulativeSecondAmortisation = cSA;
    // rawVar.investRecurDeltaRaw = iRDR;
    rawVar.cumulativeRecurringYearlyCostsOfBuyingRaw = cRYC;

    rawVar.salePriceRaw = sPriceRaw;
    rawVar.totalGainRaw = tGainRaw;
    rawVar.equityRaw = eqRaw;

    rawVar.gainsTaxRaw = gainsTaxRaw;
    rawVar.realEstateFeeAmountRaw = realEstateFeeAmountRaw;
    rawVar.sellingCostRaw = sellCostRaw;

    rawVar.opportunityCostBuyingRaw = opportunityCostBuyingRaw;
    rawVar.opportunityCostRentingRaw = opportunityCostRentingRaw;
    rawVar.netBuyProceedsRaw = netBuyProceedsRaw;

    rawVar.netBuyRaw = netBuyRaw;

    rawVar.finalRentRaw = finalRent;
    rawVar.totalRentPaidRaw = totalRentPaidRaw;
    rawVar.investDownRaw = investDownRaw;

    rawVar.netRentRaw = netRentRaw;
  }
  if (netRentOrNetBuy == "netRent") return netRentRaw as number;
  else if (netRentOrNetBuy == "netBuy") return netBuyRaw as number;

}

var comVar = reactive({

  priceDisplay: computed(() => {
    rawVar.priceRaw = parseInt(initVar.priceInput.toString().replace(/,/g, ''), 10);
    return rawVar.priceRaw.toLocaleString();
  }),

  rentDisplay: computed(() => {
    rawVar.rentRaw = parseInt(initVar.rentInput.toString().replace(/,/g, ''), 10);
    return rawVar.rentRaw.toLocaleString();
  }),
  downOwnDisplay: computed(() => {
    return rawVar.downOwnRaw.toLocaleString();
  }),
  upfrontCostsInputCom: computed(() => {
    var x = Number(initVar.upfrontCostsInput);
    if (x < 0 || x > 20) { return 0; }
    else { return initVar.upfrontCostsInput; }
  }),
  downSecondInputCom: computed(() => {
    var y = Number(initVar.downSecondInput);
    var x = Number(initVar.downOwnInput);
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
    return rawVar.downSecondRaw.toLocaleString();
  }),
  downTotalInput: computed(() => { return parseInt(initVar.downSecondInput.toString()) + parseInt(initVar.downOwnInput.toString()) }),
  downTotalDisplay: computed(() => {
    return rawVar.downTotalRaw.toLocaleString();
  }),
  mortgageRateAvg: computed(() => {
    let avg = Object.values(initVar.mortgageRateInput).reduce((a, b) => Number(a) + Number(b)) / Object.keys(initVar.mortgageRateInput).length;
    if ((avg < -50) || (avg > 50)) {
      return 1;
    } else {
      return avg.toFixed(2);
    }
  }),
  mortgageRateCom: computed(() => {
    let avg = Object.values(initVar.mortgageRateInput).reduce((a, b) => Number(a) + Number(b)) / Object.keys(initVar.mortgageRateInput).length;
    if ((avg < -50) || (avg > 50)) {
      return 1;
    } else {
      return avg;
    }
  }),
  initialMortgagedAmount: computed(() => {
    return rawVar.initialMortgageRaw.toLocaleString();
  }),
  initialFirstAmount: computed(() => {
    return rawVar.initialFirstRaw.toLocaleString();
  }),
  initialSecondAmount: computed(() => {
    return rawVar.initialSecondRaw.toLocaleString();
  }),
  firstMonthly: computed(() => {
    rawVar.firstMonthlyRaw = (Math.round(rawVar.initialFirstInterestRaw / 12 + Number(initVar.additionalFirstAmortisationPerMonth.a)));
    return rawVar.firstMonthlyRaw.toLocaleString();
  }),
  secondMonthly: computed(() => {
    rawVar.secondMonthlyRaw = (Math.round(rawVar.initialSecondInterestRaw / 12 + rawVar.secondAmortisationPerYearRaw / 12));
    return rawVar.secondMonthlyRaw.toLocaleString();
  }),
  upfrontCostsAmount: computed(() => {
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
  totalDisplayTaxDifference: computed(() => {
    var x = initVar.marginalInput;
    if (x < 0 || x >= 100) { rawVar.totalTaxDifferenceRaw = 0 }
    return Math.abs(Math.round(rawVar.totalTaxDifferenceRaw)).toLocaleString();
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
    rawVar.initialFirstInterestRaw = (initVar.mortgageRateInput.a / 100 * rawVar.initialFirstRaw);
    return rawVar.initialFirstInterestRaw.toLocaleString();
  }),
  firstAmortisation: computed(() => {
    rawVar.additionalFirstAmortisationRaw = Object.values(initVar.additionalFirstAmortisationPerMonth).reduce((accumulator, a) => Number(accumulator) + Number(a) * 5 * 12, 0)
    if (rawVar.additionalFirstAmortisationRaw > rawVar.initialFirstRaw * 1.1) { firstAmortInBounds = false; }
    else { firstAmortInBounds = true; }
    return Math.min(rawVar.additionalFirstAmortisationRaw, rawVar.initialFirstRaw).toLocaleString();
  }),
  secondInterest: computed(() => {
    rawVar.initialSecondInterestRaw = ((comVar.mortgageRateCom + comVar.secondPremiumCom) / 100 * rawVar.initialSecondRaw);
    return Math.round(rawVar.initialSecondInterestRaw).toLocaleString();
  }),
  secondLengthCom: computed(() => {
    if (initVar.secondMortgageationLength < 1) { return 1; }
    else { return Number(initVar.secondMortgageationLength); }
  }),
  secondAmortisationPerYear: computed(() => {
    return Math.round(rawVar.secondAmortisationPerYearRaw).toLocaleString();
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
    return Math.round((rawVar.totalRentPaidRaw)).toLocaleString();
  }),

  investDown: computed(() => {
    return Math.round((rawVar.investDownRaw)).toLocaleString();
  }),

  investDownSign: computed(() => {
    if (rawVar.investDownRaw >= 0) { return "green-accent-2" } else return "red-accent-1"
  }),
  buyProceedsSign: computed(() => {
    if (rawVar.netBuyProceedsRaw >= 0) { return "green-accent-2" } else return "red-accent-1"
  }),
  // investRecurSign: computed(() => {
  //   if (rawVar.investRecurDeltaRaw >= 0) { return "green-accent-2" } else return "red-accent-1"
  // }),

  netBuyLabel: computed(() => {
    if (rawVar.netBuyRaw <= 0) { return "Net Profit, Buy" } else return "Net Cost, Buy"
  }),
  netRentLabel: computed(() => {
    if (rawVar.netRentRaw <= 0) { return "Net Profit, Rent" } else return "Net Cost, Rent"
  }),
  netBuySign: computed(() => {
    if (rawVar.netBuyRaw <= 0) { return "green-accent-2" } else return "red-accent-1"
  }),
  netRentSign: computed(() => {
    if (rawVar.netRentRaw <= 0) { return "green-accent-2" } else return "red-accent-1"
  }),

  netBuyProceeds: computed(() => {
    return Math.round((rawVar.netBuyProceedsRaw)).toLocaleString();
  }),
  opportunityBuy: computed(() => {
    return Math.round((rawVar.opportunityCostBuyingRaw)).toLocaleString();
  }),
  opportunityRent: computed(() => {
    return Math.round((rawVar.opportunityCostRentingRaw)).toLocaleString();
  }),

  // investRecurDelta: computed(() => {
  //   rawVar.priceRaw = parseInt(initVar.priceInput.toString().replace(/,/g, ''), 10);
  //   rawVar.rentRaw = parseInt(initVar.rentInput.toString().replace(/,/g, ''), 10);

  //   RecurringCostCalculator(rawVar.priceRaw, rawVar.rentRaw, false);
  //   return Math.round((rawVar.investRecurDeltaRaw)).toLocaleString();
  // }),

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
    return rawVar.salePriceRaw.toLocaleString();
  }),

  realEstateFeeAmount: computed(() => {
    return Math.round(rawVar.realEstateFeeAmountRaw).toLocaleString();
  }),
  totalGain: computed(() => {
    return rawVar.totalGainRaw.toLocaleString();
  }),
  gainsTaxAmount: computed(() => {
    return rawVar.gainsTaxRaw.toLocaleString();
  }),

  initTotal: computed(() => {
    return Math.round(rawVar.initTotalRaw).toLocaleString();
  }),

  recurringTotal: computed(() => {

    rawVar.priceRaw = parseInt(initVar.priceInput.toString().replace(/,/g, ''), 10);
    rawVar.rentRaw = parseInt(initVar.rentInput.toString().replace(/,/g, ''), 10);

    // RecurringCostCalculator(Number(comVar.priceDisplay), Number(comVar.rentDisplay), false);
    RecurringCostCalculator(rawVar.priceRaw, rawVar.rentRaw, false);

    var recCost = rawVar.cumulativeRecurringYearlyCostsOfBuyingRaw;
    return Math.round(recCost).toLocaleString();
  }),
  equity: computed(() => {
    return Math.round(rawVar.equityRaw).toLocaleString();
  }),
  sellingCostAmount: computed(() => {
    return Math.round(rawVar.sellingCostRaw).toLocaleString();
  }),
  netBuyAmount: computed(() => {
    if (rawVar.netBuyRaw < 0) { return "+" + Math.round(Math.abs(rawVar.netBuyRaw)).toLocaleString(); }
    else { return "-" + Math.round(Math.abs(rawVar.netBuyRaw)).toLocaleString(); }
  }),
  netRentAmount: computed(() => {
    if (rawVar.netRentRaw < 0) { return "+" + Math.round(Math.abs(rawVar.netRentRaw)).toLocaleString(); }
    else { return "-" + Math.round(Math.abs(rawVar.netRentRaw)).toLocaleString(); }
  }),
  // totalInvestAmount: computed(() => {
  //   return Math.round(rawVar.investDownRaw + rawVar.investRecurDeltaRaw).toLocaleString();
  // }),

  equivRent: computed(() => {

    var rent = 0;
    var netRent = 0;
    var netBuyRaw = rawVar.netBuyRaw;
    if (netBuyRaw > 100000000) return "NaN";
    var priceRaw = rawVar.priceRaw;

    var notEquivYet = true;

    var stepSize = 100000;
    var netRentLast = netRent;
    var rentLast = rent;
    var loopBreak = 0;

    while (notEquivYet) {
      loopBreak++;
      if (loopBreak > 500) {break;}
      if (netRent / netBuyRaw > 1.001) {
        stepSize = stepSize / 10;
        netRent = netRentLast;
        rent = rentLast;
        loopBreak--;
      }
      if (netRent / netBuyRaw > 0.999 && netRent / netBuyRaw < 1.001) { notEquivYet = false; break;}

      rentLast = rent;
      // rent = rent + Math.min(100, (netBuyRaw - netRent) / 1000);
      rent = rent + stepSize;

      if (rent < 0 || rent > 10000000) {
        rent = 0;
        break;
      }

      netRentLast = netRent;
      netRent = RecurringCostCalculator(priceRaw, rent, true, 'netRent')!;
    }

    // console.log(loopBreak);
    return Math.round(rent).toLocaleString();

  }),

  equivPurchase: computed(() => {

    var price = 0;
    var netBuy = 0;
    var netRentRaw = rawVar.netRentRaw;
    if (netRentRaw > 100000000) return "NaN";
    var rentRaw = rawVar.rentRaw;

    var notEquivYet = true;

    var stepSize = 10000000;
    var netBuyLast = netBuy;
    var priceLast = price;
    var loopBreak = 0;

    while (notEquivYet) {
      loopBreak++;
      if (loopBreak > 500) {break;}

      if (netBuy / netRentRaw > 1.001) {
        stepSize = stepSize / 10;
        netBuy = netBuyLast;
        price = priceLast;
        loopBreak--;
      }
      if (netBuy / netRentRaw > 0.999 && netBuy / netRentRaw < 1.001) { notEquivYet = false; break;}

      priceLast = price;
      price = price + stepSize;

      if (price < 0 || price > 100000000) {
        price = 0;
        break;
      }
      netBuyLast = netBuy;
      netBuy = RecurringCostCalculator(price, rentRaw, true, 'netBuy')!;
    }

    // console.log(loopBreak);
    return Math.round(price).toLocaleString();
  })

})

const initVarFix = {
  priceInput: 1000000,
  rentInput: 3000,
  downOwnInput: 10,
  downSecondInput: 10,
  mortgageRateInput: { a: 2.5, b: 2.5, c: 2.5, d: 2.5, e: 2.5, f: 2.5, g: 2.5, h: 2.5, i: 2.5, j: 2.5, k: 2.5, l: 2.5 },
  additionalFirstAmortisationPerMonth: { a: 0, b: 0, c: 0, d: 0, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 },
  secondMortgageationLength: 15,
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

//Historical mortgage rates
const hR = [4.0, 4.4, 5.3, 5.45, 5.0, 5.35, 6.25, 4.6, 3.85, 3.3, 1.65, 1.2, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5];

//Set array for mortgage rates via buttons
function setToTwoPointFivePercentFlat() {
  var newObj = { a: 2.5, b: 2.5, c: 2.5, d: 2.5, e: 2.5, f: 2.5, g: 2.5, h: 2.5, i: 2.5, j: 2.5, k: 2.5, l: 2.5 }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setToFivePercentFlat() {
  var newObj = { a: 5, b: 5, c: 5, d: 5, e: 5, f: 5, g: 5, h: 5, i: 5, j: 5, k: 5, l: 5 }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setToIncreasing() {
  var newObj = { a: 2.5, b: 2.6, c: 2.7, d: 2.8, e: 2.9, f: 3.0, g: 3.1, h: 3.2, i: 3.3, j: 3.4, k: 3.5, l: 3.6 }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setToDecreasing() {
  var newObj = { a: 2.5, b: 2.4, c: 2.3, d: 2.2, e: 2.1, f: 2.0, g: 1.9, h: 1.8, i: 1.7, j: 1.6, k: 1.5, l: 1.5 }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setToSpikes() {
  var newObj = { a: 2.5, b: 7.5, c: 2.5, d: 2.5, e: 2.5, f: 7.5, g: 2.5, h: 2.5, i: 2.5, j: 7.5, k: 2.5, l: 2.5 }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setTo1960() {
  var i = 0;
  var newObj = { a: hR[i + 0], b: hR[i + 1], c: hR[i + 2], d: hR[i + 3], e: hR[i + 4], f: hR[i + 5], g: hR[i + 6], h: hR[i + 7], i: hR[i + 8], j: hR[i + 9], k: hR[i + 10], l: hR[i + 11] }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setTo1970() {
  var i = 2;
  var newObj = { a: hR[i + 0], b: hR[i + 1], c: hR[i + 2], d: hR[i + 3], e: hR[i + 4], f: hR[i + 5], g: hR[i + 6], h: hR[i + 7], i: hR[i + 8], j: hR[i + 9], k: hR[i + 10], l: hR[i + 11] }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setTo1980() {
  var i = 4;
  var newObj = { a: hR[i + 0], b: hR[i + 1], c: hR[i + 2], d: hR[i + 3], e: hR[i + 4], f: hR[i + 5], g: hR[i + 6], h: hR[i + 7], i: hR[i + 8], j: hR[i + 9], k: hR[i + 10], l: hR[i + 11] }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setTo1990() {
  var i = 6;
  var newObj = { a: hR[i + 0], b: hR[i + 1], c: hR[i + 2], d: hR[i + 3], e: hR[i + 4], f: hR[i + 5], g: hR[i + 6], h: hR[i + 7], i: hR[i + 8], j: hR[i + 9], k: hR[i + 10], l: hR[i + 11] }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setTo2000() {
  var i = 8;
  var newObj = { a: hR[i + 0], b: hR[i + 1], c: hR[i + 2], d: hR[i + 3], e: hR[i + 4], f: hR[i + 5], g: hR[i + 6], h: hR[i + 7], i: hR[i + 8], j: hR[i + 9], k: hR[i + 10], l: hR[i + 11] }
  Object.assign(initVar.mortgageRateInput, newObj);
}
function setTo2010() {
  var i = 10;
  var newObj = { a: hR[i + 0], b: hR[i + 1], c: hR[i + 2], d: hR[i + 3], e: hR[i + 4], f: hR[i + 5], g: hR[i + 6], h: hR[i + 7], i: hR[i + 8], j: hR[i + 9], k: hR[i + 10], l: hR[i + 11] }
  Object.assign(initVar.mortgageRateInput, newObj);
}

function resetAmortise() {
  var newObj = { a: 0, b: 0, c: 0, d: 0, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}

//Set array for amortisation amounts via buttons
function Amortise10Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (10 * 12));
  var newObj = { a: amt, b: amt, c: 0, d: 0, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise15Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (15 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: 0, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise20Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (20 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: amt, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise25Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (25 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: amt, e: amt, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise30Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (30 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: amt, e: amt, f: amt, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise40Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (40 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: amt, e: amt, f: amt, g: amt, h: amt, i: 0, j: 0, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise50Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (50 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: amt, e: amt, f: amt, g: amt, h: amt, i: amt, j: amt, k: 0, l: 0 }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
}
function Amortise60Yrs() {
  var amt = Math.round(rawVar.initialFirstRaw / (60 * 12));
  var newObj = { a: amt, b: amt, c: amt, d: amt, e: amt, f: amt, g: amt, h: amt, i: amt, j: amt, k: amt, l: amt }
  Object.assign(initVar.additionalFirstAmortisationPerMonth, newObj);
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
  history.pushState({}, "", document.location.origin + "/?id=" + foundState.id);

  // console.log("save states: ");
  // console.log(saveStates.list);
}

function removeState(idOfClicked: string) {

  var removeIndex = saveStates.list.map(item => item.id).indexOf(idOfClicked);
  ~removeIndex && saveStates.list.splice(removeIndex, 1);

}

var floor = Math.floor, abs = Math.abs, log = Math.log, round = Math.round, min = Math.min;
var abbrev = ['K', 'M', 'B']; // abbreviations in steps of 1000x; extensible if need to edit

function rnd(n: any, precision: any) {
  var prec = 10 ** precision;
  return round(n * prec) / prec;
}

function formatNum(n: any) {
  n = parseFloat(n.replace(/,/g, ''));
  var base = floor(log(abs(n)) / log(1000));
  var suffix = abbrev[min(abbrev.length - 1, base - 1)];
  base = abbrev.indexOf(suffix) + 1;
  return suffix ? rnd(n / 1000 ** base, 2) + suffix : '' + n;
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


<style>
input::-webkit-outer-spin-button,
input::-webkit-inner-spin-button {
  /* display: none; <- Crashes Chrome on hover */
  -webkit-appearance: none;
  margin: 0;
  /* <-- Apparently some margin are still there even though it's hidden */
}

input[type=number] {
  -moz-appearance: textfield;
  /* Firefox */
}

/* input[type="number"] {
  -moz-appearance: textfield;
}
input::-webkit-outer-spin-button,
input::-webkit-inner-spin-button {
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
} */
</style>

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
                <v-btn color="secondary" :variant="saveListBlink.value" v-bind="props" class="mx-2">
                  Saved Analyses
                </v-btn>
              </template>
              <v-list>
                <v-list-item v-if="saveStates.list.length < 1">
                  <v-row class="px-2 ma-0">
                    <v-card-text class="align-self-center text-caption pa-0">No Saved Analyses</v-card-text>
                  </v-row>
                </v-list-item>
                <v-list-item v-for="saveState in saveStates.list" :key="saveState.id">
                  <v-card variant="outlined" bg-color="blue" class="pa-0 mx-2" @click="loadState(saveState.id)">
                    <v-row class="px-2 ma-0">
                      <v-card-text class="align-self-center text-caption pa-0"> {{ saveStates.list.indexOf(saveState) +
                        1 }} : {{
                          formatNum(saveState.text1) }} Buy / {{ formatNum(saveState.text2) }} Rent</v-card-text>
                      <v-btn size="x-small" class="pa-0 ml-1 align-self-center" icon="mdi-close"
                        @click="removeState(saveState.id)">
                      </v-btn>
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
                  suffix="CHF" pattern="\d*"></v-text-field>
              </v-col>
              <v-col cols="12" sm="6"> <v-text-field pattern="\d*" clearable base-color="cyan-accent-2"
                  label="Enter Rent Per Month" variant="outlined" v-maska:[currOptions] v-model="initVar.rentInput"
                  suffix='CHF'></v-text-field>
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
              <v-col> <v-text-field base-color="cyan-accent-2" pattern="\d*" label="" variant="outlined" suffix="years"
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
                    While the second pillar amount can be withdrawn to contribute to the down payment, at least 10% of
                    the
                    down
                    payment must be made with own funds (liquid cash + 3rd pillar)
                    , and total down payment must be at least 20% of the purchase price.
                  </v-card-text>
                  <v-row> <v-col cols="12" sm="6"> <v-text-field type="number" base-color="cyan-accent-2" clearable
                        label="% Down from Own Funds + 3rd Pillar" variant="outlined" v-model="initVar.downOwnInput"
                        suffix="%" :rules="[rules.downOwn]"></v-text-field> </v-col>
                    <v-col cols="12" sm="6"> <v-text-field readonly label="Own Funds Down Amount" variant="outlined"
                        v-model="comVar.downOwnDisplay"></v-text-field> </v-col> </v-row>
                  <v-row class="mb-0"> <v-col class="py-0" cols="12" sm="6"> <v-text-field type="number"
                        base-color="cyan-accent-2" clearable label="% Down from 2nd Pillar" variant="outlined"
                        v-model="initVar.downSecondInput" suffix="%" :rules="[rules.down]"></v-text-field> </v-col>
                    <v-col class="py-0" cols="12" sm="6"> <v-text-field readonly label="2nd Pillar Down Amount"
                        variant="outlined" v-model="comVar.downSecondDisplay" persistent-hint
                        hint="Total withdrawal of second pillar account only possible up to age 50"></v-text-field>
                    </v-col> </v-row>
                  <v-row class="mx-2 mb-5 mt-2">
                    <p class="text-caption text-medium-emphasis">Generally second pillar 'investment' has a very low
                      growth/interest rate, so this analysis excludes the '2nd Pillar Down Amount' from the 'Investment
                      Returns' calculated later.</p>
                  </v-row>
                  <v-row class="mb-4"> <v-col cols="12" sm="6"> <v-text-field type="number" base-color="cyan-accent-2"
                        clearable label="Other Costs as % of Price" persistent-hint
                        hint="Notary fees, property transfer tax, etc" variant="outlined"
                        v-model="initVar.upfrontCostsInput" suffix="%" :rules="[rules.posrate]"></v-text-field> </v-col>
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
              <v-col class="py-0"> <v-text-field readonly type="number" hide-spin-buttons label="(Assumed avg. rate)"
                  variant="outlined" v-model="comVar.mortgageRateAvg" suffix="%" :rules="[rules.rate]"></v-text-field>
              </v-col>
            </v-row>

            <v-expand-transition>
              <div v-show="showMortgage.value">

                <v-row class="text-body-1 text-sm-h6 mx-6 my-1"> Mortgage Rate Scenarios - or enter custom values per 5
                  year
                  increment </v-row>
                <v-row>
                  <v-col class="ml-2">
                    <v-btn class="ma-2" variant="outlined" @click="setToTwoPointFivePercentFlat">2.5% Flat</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setToFivePercentFlat">5% Flat</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setToIncreasing">Increasing</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setToDecreasing">Decreasing</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setToSpikes">Spikes</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setTo1960">Starting 1960</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setTo1970">...1970</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setTo1980">...1980</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setTo1990">...1990</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setTo2000">...2000</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="setTo2010">...2010</v-btn>
                  </v-col>
                </v-row>
                <v-row>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Rate, Years 0-5" variant="outlined"
                      v-model="initVar.mortgageRateInput.a" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 5-10" variant="outlined"
                      v-model="initVar.mortgageRateInput.b" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 10-15" variant="outlined"
                      v-model="initVar.mortgageRateInput.c" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 15-20" variant="outlined"
                      v-model="initVar.mortgageRateInput.d" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 20-25" variant="outlined"
                      v-model="initVar.mortgageRateInput.e" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 25-30" variant="outlined"
                      v-model="initVar.mortgageRateInput.f" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 30-35" variant="outlined"
                      v-model="initVar.mortgageRateInput.g" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 35-40" variant="outlined"
                      v-model="initVar.mortgageRateInput.h" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 40-45" variant="outlined"
                      v-model="initVar.mortgageRateInput.i" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 45-50" variant="outlined"
                      v-model="initVar.mortgageRateInput.j" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <!-- <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 50-55" variant="outlined"
                      v-model="initVar.mortgageRateInput.k" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 55-60" variant="outlined"
                      v-model="initVar.mortgageRateInput.l" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col> -->
                </v-row>
                <v-row class="text-body-1 text-sm-h6 mx-6 mt-2">Extra 1st Mortgage
                  Amortisation per Month - or enter custom values per 5 year increment</v-row>
                <v-row>
                  <v-col class="ml-2">
                    <v-btn class="ma-2" variant="outlined" @click="Amortise10Yrs">Fully Amortise in 10 Years</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="Amortise15Yrs">... in 15 Years</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="Amortise20Yrs">... in 20 Years</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="Amortise25Yrs">... in 25 Years</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="Amortise30Yrs">... in 30 Years</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="Amortise40Yrs">... in 40 Years</v-btn>
                    <v-btn class="ma-2" variant="outlined" @click="Amortise50Yrs">... in 50 Years</v-btn>
                    <!-- <v-btn class="ma-2" variant="outlined" @click="Amortise60Yrs">... in 60 Years</v-btn> -->
                    <v-btn class="ma-2" variant="outlined" @click="resetAmortise">Reset</v-btn>
                  </v-col>
                </v-row>

                <v-row>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Amount, Years 0-5" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.a"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 5-10" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.b"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 10-15" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.c"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 15-20" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.d"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 20-25" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.e"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 25-30" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.f"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 30-35" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.g"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 35-40" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.h"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 40-45" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.i"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 45-50" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.j"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 50-55" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.k"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                  <v-col class="pb-0" cols="4" md="3" lg="2"> <v-text-field type="number" clearable
                      base-color="cyan-accent-2" label="Years 55-∞" variant="outlined"
                      v-model="initVar.additionalFirstAmortisationPerMonth.l"
                      :rules="[rules.positiveIntegerOrZero]"></v-text-field> </v-col>
                </v-row>


                <v-row class="mt-2"> <v-col> <v-card text="Years to Second Mortgage Amortisation"></v-card> </v-col>
                  <v-col> <v-text-field base-color="cyan-accent-2" pattern="\d*" variant="outlined"
                      label="Max 15 years by law" :rules="[rules.second]"
                      v-model="initVar.secondMortgageationLength"></v-text-field> </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card text="Total Initial Mortgaged Amount"></v-card>
                  </v-col>
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

                <v-row class="my-0"> <v-col class="py-0"> <v-card
                      text="Cumulative Extra First Mortgage Amortisation (max 100% of first mortgage)"></v-card>
                  </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined" :rules="[rules.firstAmortRule]"
                      v-model="comVar.firstAmortisation"></v-text-field>
                  </v-col>
                </v-row>

                <v-row class="my-0"> <v-col class="py-0"> <v-card
                      text="First Mortgage, Initial Interest per Year (Years 0-5)"></v-card>
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

                <v-row class="my-0"> <v-col class="py-0"> <v-card
                      text="Second Mortgage, Amortisation per Year"></v-card>
                  </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.secondAmortisationPerYear"></v-text-field>
                  </v-col>
                </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">The second mortgage typically carries a premium of
                    0.5-1%
                    above the first mortgage interest rate. </p>
                </v-row>
                <v-row>
                  <v-col class="pb-0" cols="12" sm="6"> <v-text-field type="number" clearable base-color="cyan-accent-2"
                      label="% Premium" variant="outlined" v-model="initVar.secondPremiumInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field> </v-col>
                  <!-- <v-col> <v-card text="Second Mortgage, Interest per Year"></v-card> </v-col> -->
                  <v-col class="pb-0" cols="12" sm="6"> <v-text-field readonly
                      label="Second Mortgage, Interest per Year (Years 0-5)" variant="outlined"
                      v-model="comVar.secondInterest"></v-text-field> </v-col>
                </v-row>
                <v-row class="mb-0"> <v-col class="py-0"> <v-card
                      text="Initial First Mortgage Monthly Payments (Years 0-5)"></v-card>
                  </v-col>
                  <v-col class="py-0"> <v-text-field readonly variant="outlined"
                      v-model="comVar.firstMonthly"></v-text-field>
                  </v-col>
                </v-row>

                <v-row class="my-0"> <v-col> <v-card
                      text="Initial Second Mortgage Monthly Payments (Years 0-5)"></v-card>
                  </v-col>
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
                <v-row> <v-col> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="% of Purchase Price" variant="outlined" v-model="initVar.maintInput" suffix="%"
                      :rules="[rules.posrate]"></v-text-field>
                  </v-col>
                  <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined"
                      v-model="comVar.maintAmount" suffix="CHF"></v-text-field> </v-col> </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">
                    <span class="font-weight-bold text-body-2 text-high-emphasis">Inputed rental value, </span>
                    or Eigenmietwert, is counted as
                    additional income for personal taxes.
                    However, mortgage interest and maintenance can be deducted in order to offset this additional
                    income.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="Marginal Income Tax Rate" variant="outlined" v-model="initVar.marginalInput" suffix="%"
                      :rules="[rules.numberIn100]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly
                      label="Extra Income Tax Per Year (Average Over All Years)" persistent-hint variant="outlined"
                      v-model="comVar.totalDisplayTaxDifference" suffix="CHF"></v-text-field> </v-col>
                  <!-- <v-col cols="12" sm="4"> <v-text-field readonly label="Extra Income Tax Per Year (Average Over All Years)" persistent-hint
                      hint="(1st+2nd Mortgages)" variant="outlined" v-model="comVar.totalDisplayTaxDifference"
                      suffix="CHF"></v-text-field> </v-col> -->
                  <!-- <v-col cols="12" sm="4"> <v-text-field readonly persistent-hint hint="(1st Mortgage Only)"
                      variant="outlined" v-model="comVar.marginalOnlyFirstAmount" suffix="CHF"></v-text-field> </v-col> -->
                </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">
                    <span class="font-weight-bold text-body-2 text-high-emphasis">Eigenmietwert </span>
                    is often calculated from a fraction of the actual purchase price.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="Eigenmietwert Value" persistent-hint hint="(as % of Price)" variant="outlined"
                      v-model="initVar.eigenInput" suffix="%" :rules="[rules.numberIn100]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Eigenmietwert" variant="outlined"
                      v-model="comVar.eigenValue" suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Eigenmietwert 'Income'" variant="outlined"
                      persistent-hint hint="(per year)" v-model="comVar.eigenAmount" suffix="CHF"></v-text-field>
                  </v-col>
                </v-row>

                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption">
                    <span class="font-weight-bold text-body-2 text-high-emphasis">Property Tax</span>
                    only exists in some cantons, and is levied at a percentage of the purchase price.
                  </p>
                </v-row>
                <v-row> <v-col cols="12" sm="6"> <v-text-field type="number" base-color="cyan-accent-2" clearable
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
                <v-row> <v-col cols="12" sm="6"> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="Return Rate, Per Year" variant="outlined" v-model="initVar.investInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field>
                  </v-col>
                  <!-- <v-col cols="12" sm="6"> <v-text-field readonly label="Extra Profit from Investing" persistent-hint
                      hint="(Extra money if you rent vs buy)" variant="outlined" v-model="comVar.totalInvestAmount"
                      suffix="CHF"></v-text-field> </v-col>  -->
                </v-row>
                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Property Price Growth Rate</span> is
                    typically
                    1-1.5% in urban areas of Switzerland over the last 50 years</p>
                </v-row>
                <v-row> <v-col cols="12" sm="4"> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="Growth Rate, Per Year" variant="outlined" v-model="initVar.houseRateInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field>
                  </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Final Property Value" variant="outlined"
                      v-model="comVar.salePrice" suffix="CHF"></v-text-field> </v-col>
                  <v-col cols="12" sm="4"> <v-text-field readonly label="Total Property Gain" variant="outlined"
                      v-model="comVar.totalGain" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row>
                  <p class="mx-4 text-medium-emphasis text-caption"><span
                      class="font-weight-bold text-body-2 text-high-emphasis">Rental Price Growth Rate</span> is
                    typically
                    coupled to both property price growth rates and interest rates, but can differ over time</p>
                </v-row>
                <v-row> <v-col> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="Growth Rate, Per Year" variant="outlined" v-model="initVar.rentRateInput" suffix="%"
                      :rules="[rules.rate]"></v-text-field>
                  </v-col>
                  <v-col> <v-text-field readonly label="Final Monthly Rent" hint="(In Final Year Of Analysis)"
                      persistent-hint variant="outlined" v-model="comVar.finalRent" suffix="CHF"></v-text-field>
                  </v-col>
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
                <v-row> <v-col cols="12" sm="4"> <v-text-field type="number" base-color="cyan-accent-2" clearable
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
                <v-row> <v-col cols="12" sm="4"> <v-text-field type="number" base-color="cyan-accent-2" clearable
                      label="Tax Rate" variant="outlined" persistent-hint hint="(% of Gains As Tax)"
                      v-model="initVar.gainsTaxInput" suffix="%" :rules="[rules.rate]"></v-text-field> </v-col>
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
                      suffix="CHF"></v-text-field>
                  </v-col>
                  <v-col></v-col>
                </v-row>
                <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Recurring Costs, Buy"
                      variant="outlined" v-model="comVar.recurringTotal" persistent-hint
                      hint="(Mortgage, Taxes, Maintenance, etc.)" suffix="CHF"></v-text-field> </v-col>
                  <v-col> <v-text-field base-color="red-accent-1" readonly label="Recurring Costs, Rent"
                      variant="outlined" v-model="comVar.totalRentPaid" persistent-hint hint="(Total Rent Paid)"
                      suffix="CHF"></v-text-field>
                  </v-col>
                </v-row>
                <v-row>
                  <v-col> <v-text-field base-color="red-accent-1" readonly label="Opportunity Costs, Buy"
                      persistent-hint hint="(Investment Returns on Initial + Recurring Costs)" variant="outlined"
                      v-model="comVar.opportunityBuy" suffix="CHF"></v-text-field> </v-col>
                  <v-col> <v-text-field base-color="red-accent-1" readonly label="Opportunity Costs, Rent"
                      persistent-hint hint="(Investment Returns on Recurring Costs)" variant="outlined"
                      v-model="comVar.opportunityRent" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-row class="mb-2"> <v-col> <v-text-field :base-color="comVar.buyProceedsSign" readonly
                      label="Net Proceeds, Buying" variant="outlined" v-model="comVar.netBuyProceeds" persistent-hint
                      hint="(Equity - Sale Costs)" suffix="CHF"></v-text-field> </v-col>
                  <v-col> </v-col>
                </v-row>
                <!-- <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Selling Costs"
                      variant="outlined" v-model="comVar.sellingCostAmount" suffix="CHF"></v-text-field> </v-col>
                  <v-col></v-col>
                </v-row> -->

                <v-divider :thickness="4" class="border-opacity-50 mb-2"> </v-divider>
                <v-card-text class="py-0 text-high-emphasis text-subtitle-1">Net Costs, Buying vs. Renting after
                  {{ comVar.yearsTotalCom }} Years</v-card-text>
                    <v-card-text class="mb-2 mt-0 pa-0 pb-2 text-medium-emphasis text-caption">A simple way to visualize
                      these numbers is: if you compared yourself to your doppelgänger who was magically living somewhere for free (compared to these buying and
                      renting scenarios), how much less than them would you have in your account after {{ comVar.yearsTotalCom }} years?
                    </v-card-text>
                <v-row> <v-col> <v-text-field :base-color="comVar.netBuySign" readonly :label="comVar.netBuyLabel"
                      variant="outlined" v-model="comVar.netBuyAmount" suffix="CHF"></v-text-field> </v-col>

                  <v-col> <v-text-field :base-color="comVar.netRentSign" readonly :label="comVar.netRentLabel"
                      variant="outlined" v-model="comVar.netRentAmount" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-divider :thickness="4" class="border-opacity-50 mb-4"> </v-divider>
                <v-row> <v-col>

                    <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                      <span class="text-high-emphasis"> {{ comVar.priceDisplay }} CHF</span>
                      <div v-if="rawVar.netBuyRaw < 0">
                      purchase with these assumptions, renting will never make more financial sense.
                      </div>
                      <div v-else>
                      purchase with these assumptions, if you could find an equivalent rental cheaper than approx.
                      <br>
                      <span class="text-high-emphasis"> {{ comVar.equivRent }} CHF</span>
                      <span class="text-medium-emphasis"> it would make more sense to rent.</span>
                      </div>
                    </v-card-text>
                  </v-col>
                  <v-col>
                    <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                      <span class="text-high-emphasis"> {{ initVar.rentInput }} CHF per month</span>

                      <div v-if="rawVar.netBuyRaw < 0">
                      rental with these assumptions, buying will always make more financial sense.
                      </div>
                      <div v-else>
                      rental with these assumptions, if you could find an equivalent purchase cheaper than approx.
                      <br>
                      <span class="text-high-emphasis"> {{ comVar.equivPurchase }} CHF</span>
                      <span class="text-medium-emphasis"> it would make more sense to purchase.</span>
                      </div>

                    </v-card-text>
                  </v-col>
                </v-row>
              </v-col>
            </v-row>
          </v-navigation-drawer>
        </div>

        <div v-if=smAndDown>
          <v-navigation-drawer permanent class="py-2 pl-4 pr-4" :width="showMiniDrawer.value ? 250 : 155" touchless
            location="bottom">
            <v-row>
              <v-col>
                <v-row class="align-self-start"> <v-col class="ma-0 mt-1 px-2 align-self-center">
                    <v-card-text cols="10" class="py-0 text-high-emphasis text-body-2 align-self-center">Net Costs after
                      {{ comVar.yearsTotalCom }} Years</v-card-text>
                  </v-col>
                  <v-col cols="2" class="pa-2 mt-1 align-self-center">
                    <v-btn class="align-self-center"
                      :icon="showMiniDrawer.value ? 'mdi-minus-circle' : 'mdi-plus-circle'"
                      @click="showMiniDrawer.value = !showMiniDrawer.value"></v-btn>
                  </v-col>
                </v-row>



                <v-row class="mt-2"> <v-col class="mx-2 pa-0 px-2"> <v-text-field :base-color="comVar.netBuySign"
                      readonly :label="comVar.netBuyLabel" variant="outlined" v-model="comVar.netBuyAmount"
                      suffix="CHF"></v-text-field> </v-col>

                  <v-col class="ml-2 mr-6 pa-0 px-2"> <v-text-field :base-color="comVar.netRentSign" readonly
                      :label="comVar.netRentLabel" variant="outlined" v-model="comVar.netRentAmount"
                      suffix="CHF"></v-text-field> </v-col>
                </v-row>

                <v-expand-transition>

                  <div v-show="showMiniDrawer.value">

                    <v-card-text class="mb-2 mt-0 pa-0 pb-2 text-medium-emphasis text-caption">A simple way to visualize
                      these numbers is: if you compared yourself to your doppelgänger who was magically living somewhere for free (compared to these buying and
                      renting scenarios), how much less than them would you have in your account after {{ comVar.yearsTotalCom }} years?
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
                          suffix="CHF"></v-text-field>
                      </v-col>
                      <v-col></v-col>
                    </v-row>
                    <v-row> <v-col> <v-text-field base-color="red-accent-1" readonly label="Recurring Costs, Buy"
                          variant="outlined" v-model="comVar.recurringTotal" persistent-hint
                          hint="(Mortgage, Taxes, Maintenance, etc.)" suffix="CHF"></v-text-field> </v-col>
                      <v-col> <v-text-field base-color="red-accent-1" readonly label="Recurring Costs, Rent"
                          variant="outlined" v-model="comVar.totalRentPaid" persistent-hint hint="(Total Rent Paid)"
                          suffix="CHF"></v-text-field> </v-col>
                    </v-row>
                    <v-row>
                      <v-col> <v-text-field base-color="red-accent-1" readonly label="Opportunity Costs, Buy"
                          persistent-hint hint="(Investment Returns on Initial + Recurring Costs)" variant="outlined"
                          v-model="comVar.opportunityBuy" suffix="CHF"></v-text-field> </v-col>
                      <v-col> <v-text-field base-color="red-accent-1" readonly label="Opportunity Costs, Rent"
                          persistent-hint hint="(Investment Returns on Recurring Costs)" variant="outlined"
                          v-model="comVar.opportunityRent" suffix="CHF"></v-text-field> </v-col>
                    </v-row>
                    <v-row class="mb-2"> <v-col> <v-text-field :base-color="comVar.buyProceedsSign" readonly
                          label="Net Proceeds, Buying" variant="outlined" v-model="comVar.netBuyProceeds"
                          persistent-hint hint="(Equity - Sale Costs)" suffix="CHF"></v-text-field> </v-col>
                      <v-col> </v-col>
                    </v-row>

                    <v-row> <v-col>

                    <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                      <span class="text-high-emphasis"> {{ comVar.priceDisplay }} CHF</span>
                      <div v-if="rawVar.netBuyRaw < 0">
                      purchase with these assumptions, renting will never make more financial sense.
                      </div>
                      <div v-else>
                      purchase with these assumptions, if you could find an equivalent rental cheaper than approx.
                      <br>
                      <span class="text-high-emphasis"> {{ comVar.equivRent }} CHF</span>
                      <span class="text-medium-emphasis"> it would make more sense to rent.</span>
                      </div>
                    </v-card-text>
                  </v-col>
                  <v-col>
                    <v-card-text class="pt-0 ma-0 text-medium-emphasis text-caption">Compared to a <br>
                      <span class="text-high-emphasis"> {{ initVar.rentInput }} CHF per month</span>

                      <div v-if="rawVar.netBuyRaw < 0">
                      rental with these assumptions, buying will always make more financial sense.
                      </div>
                      <div v-else>
                      rental with these assumptions, if you could find an equivalent purchase cheaper than approx.
                      <br>
                      <span class="text-high-emphasis"> {{ comVar.equivPurchase }} CHF</span>
                      <span class="text-medium-emphasis"> it would make more sense to purchase.</span>
                      </div>

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
