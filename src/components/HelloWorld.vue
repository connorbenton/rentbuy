<script setup lang="ts">
import { ref, watch, reactive, computed, nextTick } from 'vue'
import { resourceLimits } from 'worker_threads';
import { vMaska } from 'maska'
import { reverse } from 'dns';
import { format } from 'path';
import { json } from 'stream/consumers';
import { exportAllDeclaration } from '@babel/types';
import dJSON from 'dirty-json';

// Rules for evaluating form input
const rules = {
  down: (value: number) => (rawVar.downTotalRaw / rawVar.priceRaw >= 0.2 && rawVar.downTotalRaw / rawVar.priceRaw < 1) || 'Total Down payment must be at least 20 and not more than 100 percent',
  downOwn: (value: number) => (Number(value) >= 10 && Number(value) < 100) || 'Down payment own funds must be at least 10 percent',
  second: (value: number) => (Number(value) <= 15 && Number(value) > 0 && Number.isInteger(Number(value))) || 'Amortization must be an integer between 1 and 15 years',
  positiveInteger: (value: number) => (Number.isInteger(Number(value)) && Number(value) > 0) || 'Value must be a positive integer',
  number: (value: string) => (Number.isFinite(Number(value)) && value != "") || 'Value must be a number'
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
  let url = 'https://o3dpyfo8of.execute-api.eu-central-1.amazonaws.com/prod';

  console.log(strCom)
  let stringifiedBody = JSON.stringify({
    dataUUID: hashVal,
    // allData: strAllData
    comVar: strCom,
    rawVar: strRaw,
    initVar: strInit
    //  comVar: (comVar),
    // rawVar: (rawVar),
    // initVar: (initVar)   
  })

  console.log(stringifiedBody);
  stringifiedBody = stringifiedBody.replace(/(\r\n|\n|\r)/gm, "");
  console.log(stringifiedBody);

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
    console.log(data);
    // do something with data
  }
  return cyrb53(JSON.stringify(allData));
}

// const dynamoData = ref([])

const GetDynamoData = async () => {
  var link = document.location.href.split('/');
  var id = link[3];
  if (id === "") return;
  let url = 'https://o3dpyfo8of.execute-api.eu-central-1.amazonaws.com/prod/' + id;

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
    console.log(data);
    if (data.dataHashes.length > 0) {
      // console.log(data.dataHashes[0].rawVar);
      // console.log("before")
      // // console.log(rawVar);
      // // console.log(comVar);
      // console.log(initVar);
      var i = JSON.parse(atob((data.dataHashes[0].initVar)));
      var r = JSON.parse(atob((data.dataHashes[0].rawVar)));
      var c = JSON.parse(atob((data.dataHashes[0].comVar)));
      // console.log(i)
      // console.log(i.priceInput);
      // initVar.priceInput = i.priceInput;

      Object.keys(initVar).forEach((key:string) => {
        initVar[key as keyof typeof initVar] = i[key];
      });
      Object.keys(rawVar).forEach((key:string) => {
        rawVar[key as keyof typeof rawVar] = r[key];
      });
      // Object.keys(comVar).forEach((key:string) => {
      //   comVar[key as keyof typeof comVar] = c[key];
      // });

      // comVar = JSON.parse(atob((data.dataHashes[0].comVar)));
      // initVar = JSON.parse(atob((data.dataHashes[0].initVar)));
    }

    // do something with data

    // console.log("after")
    // console.log(rawVar);
    // console.log(comVar);
    // console.log(initVar);
    // console.log(trawVar);
  }
}

GetDynamoData()
// console.log(rawVar);

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

var comVar = reactive({

  priceDisplay: computed(() => {
    rawVar.priceRaw = parseInt(initVar.priceInput.toString().replace(/,/g, ''), 10);
    return rawVar.priceRaw.toLocaleString();
  }),
  downOwnDisplay: computed(() => {
    rawVar.downOwnRaw = Number(comVar.priceDisplay);
    rawVar.downOwnRaw = (initVar.downOwnInput / 100 * rawVar.priceRaw);
    return rawVar.downOwnRaw.toLocaleString();
  }),
  downSecondDisplay: computed(() => {
    rawVar.downSecondRaw = (initVar.downSecondInput / 100 * rawVar.priceRaw);
    return rawVar.downSecondRaw.toLocaleString();
  }),
  downTotalInput: computed(() => { return parseInt(initVar.downSecondInput.toString()) + parseInt(initVar.downOwnInput.toString()) }),
  downTotalDisplay: computed(() => {
    rawVar.downTotalRaw = (rawVar.downOwnRaw + rawVar.downSecondRaw);
    return rawVar.downTotalRaw.toLocaleString();
  }),
  mortgageRateCom: computed(() => {
    return Number(initVar.mortgageRateInput);
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
    rawVar.firstMonthlyRaw = (Math.max(rawVar.initialMortgageRaw - rawVar.initialFirstRaw, 0));
    return rawVar.firstMonthlyRaw.toLocaleString();
  }),
  secondMonthly: computed(() => {
    rawVar.secondMonthlyRaw = (Math.max(rawVar.initialMortgageRaw - rawVar.initialFirstRaw, 0));
    return rawVar.secondMonthlyRaw.toLocaleString();
  }),
  upfrontCostsAmount: computed(() => {
    rawVar.upfrontCostsRaw = (initVar.upfrontCostsInput / 100 * rawVar.priceRaw);
    return rawVar.upfrontCostsRaw.toLocaleString();
  }),
  maintAmount: computed(() => {
    rawVar.maintRaw = (initVar.maintInput / 100 * rawVar.priceRaw);
    return rawVar.maintRaw.toLocaleString();
  }),
  marginalAmount: computed(() => {
    rawVar.marginalRaw = (initVar.marginalInput / 100 * (rawVar.eigenRaw - rawVar.maintRaw - rawVar.firstInterestRaw - rawVar.secondInterestRaw));
    return rawVar.marginalRaw.toLocaleString();
  }),
  marginalOnlyFirstAmount: computed(() => {
    rawVar.marginalOnlyFirstRaw = (initVar.marginalInput / 100 * (rawVar.eigenRaw - rawVar.maintRaw - rawVar.firstInterestRaw));
    return rawVar.marginalOnlyFirstRaw.toLocaleString();
  }),
  eigenAmount: computed(() => {
    rawVar.eigenRaw = (initVar.eigenInput / 100 * .0425 * rawVar.priceRaw);
    return rawVar.eigenRaw.toLocaleString();
  }),
  propTaxAmount: computed(() => {
    rawVar.marginalRaw = (initVar.marginalInput / 100 * rawVar.priceRaw);
    return rawVar.propTaxRaw.toLocaleString();
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
    return Number(initVar.investInput);
  }),
  houseRateCom: computed(() => {
    return Number(initVar.houseRateInput);
  }),
  rentRateCom: computed(() => {
    return Number(initVar.rentRateInput);
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
    var x = rawVar.downOwnRaw;
    for (var i = 0; i < comVar.yearsTotalCom; i++) {
      x = x * (1 + Number(comVar.investCom) / 100);
    }
    rawVar.investDownRaw = x;
    return Math.round((rawVar.investDownRaw)).toLocaleString();
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
    return Number(initVar.yearsInProperty);
  }),
  secondPremiumCom: computed(() => {
    return Number(initVar.secondPremiumInput);
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
    return (rawVar.maintRaw + rawVar.secondAmortisationRaw + rawVar.secondInterestRaw + rawVar.firstInterestRaw + rawVar.marginalRaw);
  }),

  recurringYearlyCostAfterSecondDone: computed(() => {
    return (rawVar.firstInterestRaw + rawVar.maintRaw + rawVar.marginalOnlyFirstRaw);
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

})


var initVar = reactive({
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
  rentRateInput: 0.5,
  secondPremiumInput: 1,
  gainsTaxInput: 25,
  realEstateFeeInput: 4
})






const currOptions = { mask: ["#,###,###,###", "###,###,###", "##,###,###", "#,###,###", "###,###", "##,###", "#,###", "###", "##", "#"], reverse: true }
</script>

<template>
  <v-container>
    <v-row><v-btn @click="hash">Calculate Hash</v-btn> </v-row>
    <v-row>
      <v-col>
        <v-card class="mx-2 px-4">
          <v-card-title> Property Purchase Price vs. Property Rent</v-card-title>
          <v-row class="pt-2"> <v-col> <v-text-field clearable label="Enter Purchase Price" variant="outlined"
                v-maska:[currOptions] v-model="initVar.priceInput" suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field clearable label="Enter Rent Per Month" variant="outlined" v-maska:[currOptions]
                v-model="initVar.rentInput" suffix="CHF"></v-text-field> </v-col>
          </v-row>
        </v-card>

        <v-card class="ma-2 px-4">
          <v-card-title> Total Years Living In Property (vs. Renting)</v-card-title>
          <v-card-text>
            Generally speaking, over a shorter timeframe renting is more advantageous, as upfront fees can be high with
            buying.
          </v-card-text>
          <v-row>
            <v-col> <v-text-field label="TODO DONE add rule for integer" variant="outlined" suffix="years"
                v-model="initVar.yearsInProperty" :rules="[rules.positiveInteger]"></v-text-field> </v-col>
            <!-- <v-col> <v-card text="The upfront costs
              of buying are better spread out over many years"></v-card> </v-col> -->
          </v-row>
        </v-card>

        <v-form ref="form" validate-on="input" class="ma-2">
          <v-card class="pa-2">
            <v-card-title> Down Payment</v-card-title>
            <v-card-text>
              While the second pillar amount can be withdrawn to contribute to the down payment, at least 10% of the down
              payment must be made with own funds (liquid cash + 3rd pillar)
              , and total down payment must be at least 20% of the purchase price.
            </v-card-text>
            <v-row> <v-col> <v-text-field clearable label="% Down from Own Funds + 3rd Pillar" variant="outlined"
                  v-model="initVar.downOwnInput" suffix="%" :rules="[rules.downOwn]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="Own Funds Down Amount" variant="outlined"
                  v-model="comVar.downOwnDisplay"></v-text-field> </v-col> </v-row>
            <v-row> <v-col> <v-text-field clearable label="% Down from 2nd Pillar" variant="outlined"
                  hint="Total withdrawal only possible up to age 50" v-model="initVar.downSecondInput" suffix="%"
                  :rules="[rules.down]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="2nd Pillar Down Amount" variant="outlined"
                  v-model="comVar.downSecondDisplay"></v-text-field> </v-col> </v-row>
            <v-row> <v-col> <v-text-field readonly label="Percent Down Payment Total" variant="outlined"
                  v-model="comVar.downTotalInput" suffix="%" :rules="[rules.down]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="Down Payment Total Amount" variant="outlined"
                  v-model="comVar.downTotalDisplay"></v-text-field> </v-col> </v-row>
          </v-card>
        </v-form>

        <v-card class="ma-2 pa-2">
          <v-card-title> Mortgage Details </v-card-title>
          <v-card-text>
            test
          </v-card-text>

          <v-row> <v-col> <v-card text="Mortgage Interest Rate"></v-card> </v-col>
            <v-col> <v-text-field label="TODO DONE add number check rule" variant="outlined"
                v-model="initVar.mortgageRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Years to Second Mortgage Amortization"></v-card> </v-col>
            <v-col> <v-text-field variant="outlined" label="TODO DONE make rules check force this as int"
                :rules="[rules.second]" v-model="initVar.secondMortgageAmortizationLength"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total Initial Mortgaged Amount"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.initialMortgagedAmount"></v-text-field>
            </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total First Mortgage amount (max 67% of purchase price)"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.initialFirstAmount"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="First Mortgage, Interest per Year"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.firstInterest"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total Second Mortgage amount (max 13% of purchase price)"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.initialSecondAmount"></v-text-field>
            </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Second Mortgage, Amortisation per Year"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.secondAmortisation"></v-text-field> </v-col>
          </v-row>

          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">The second mortgage typically carries a premium of 0.5-1%
              above the first mortgage interest rate. </p>
          </v-row>
          <v-row>
            <v-col> <v-text-field clearable label="% Premium" variant="outlined" v-model="initVar.secondPremiumInput"
                suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <!-- <v-col> <v-card text="Second Mortgage, Interest per Year"></v-card> </v-col> -->
            <v-col> <v-text-field readonly label="Second Mortgage, Interest per Year" variant="outlined"
                v-model="comVar.secondInterest"></v-text-field> </v-col>
          </v-row>
          <v-row> <v-col> <v-card text="Total First Mortgage Monthly Payments"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.firstMonthly"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total Second Mortgage Monthly Payments"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="comVar.secondMonthly"></v-text-field> </v-col>
          </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title> Upfront Costs</v-card-title>
          <v-card-text>
            This can differ sharply by canton - includes notary/registration fees, property transfer tax, etc.
          </v-card-text>
          <v-row> <v-col> <v-text-field clearable label="Costs as % of Purchase Price" variant="outlined"
                v-model="initVar.upfrontCostsInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Upfront Costs Amount" variant="outlined"
                v-model="comVar.upfrontCostsAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title> Annual Non-Mortgage Costs</v-card-title>
          <v-card-text>
          </v-card-text>
          <v-row>
            <p class="mx-4 mb-4 text-high-emphasis text-body-2"> Annual recurring costs include taxes, maintenance,
              insurance, etc. </p>
          </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2"><span
                class="font-weight-bold text-body-1 text-high-emphasis"> Maintenance</span> per year is usually between
              0.5 and 1% of purchase price </p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="% of Purchase Price" variant="outlined"
                v-model="initVar.maintInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined" v-model="comVar.maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>

          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2"> Imputed rental value, or Eigenmietwert, is counted as
              additional income for personal taxes.
              However, mortgage interest and maintenance can be deducted in order to offset this additional income. TODO
              deductions offset income, not tax directly
              Also check v-text-field label overflow
            </p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Marginal Income Tax Rate" variant="outlined"
                v-model="initVar.marginalInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Extra Income Tax Per Year" persistent-hint hint="(1st+2nd Mortgages)"
                variant="outlined" v-model="comVar.marginalAmount" suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field readonly persistent-hint hint="(1st Mortgage Only)" variant="outlined"
                v-model="comVar.marginalOnlyFirstAmount" suffix="CHF"></v-text-field> </v-col>
          </v-row>

          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">Eigenmietwert is often calculated from a fraction of the
              actual purchase price. TODO add an expander to hide the next rows under imputed rental value?</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Eigenmietwert Value as % of Price - TODO make slider?"
                variant="outlined" v-model="initVar.eigenInput" suffix="%" :rules="[rules.number]"></v-text-field>
            </v-col>
            <v-col> <v-text-field readonly label="Eigenmietwert Income per Year" variant="outlined"
                v-model="comVar.eigenAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
          <!-- <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">TODO move this row to Mortgage section, also figure out how to fit all label text inside text-field</p> </v-row>
          <v-row> <v-col> <v-text-field readonly label="Mortgage Interest Per Year" ></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="First Mortgage" variant="outlined" v-model="firstInterest" suffix="CHF"></v-text-field> </v-col> 
            <v-col> <v-text-field readonly label="Second Mortgage" variant="outlined" v-model="secondInterest" suffix="CHF"></v-text-field> </v-col> 
          </v-row> -->

          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2"> Property Tax only exists in some cantons, and is levied at a
              percentage of the purchase price.</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="% of Purchase Price" variant="outlined"
                v-model="initVar.propTaxInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Property Tax Per Year" variant="outlined" v-model="comVar.propTaxAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title>Assumptions for the Future</v-card-title>
          <v-row>
            <p class="ma-4 text-high-emphasis text-body-2"> These values can strongly affect outcomes. All additional
              money saved via differences in initial or recurring costs are assumed to be invested and growing
              at the rate set below. TODO make all of these columns?
            </p>
          </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">*Average Investment Return Rate* (TODO bold) - Growth rate,
              not accounting for inflation, is around 9% for global equities over the last century, but lower for various
              fixed-income portfolios.
              For an accurate comparison to the buying values here, this value should be adjusted to reflect post-tax
              gains (i.e. dividend income tax, capital gains tax in some limited circumstances).
            </p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Return Rate, Per Year" variant="outlined"
                v-model="initVar.investInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined" v-model="comVar.maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">*Property Price Growth Rate* (TODO bold) is typically 1-1.5%
              in urban areas of Switzerland over the last 50 years</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Growth Rate, Per Year" variant="outlined"
                v-model="initVar.houseRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Final Property Value" variant="outlined" v-model="comVar.maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">*Rental Price Growth Rate* (TODO bold) is typically coupled
              to both property price growth rates and interest rates, but can differ over time</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Growth Rate, Per Year" variant="outlined"
                v-model="initVar.rentRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Final Monthly Rent" hint="(In Final Year Of Analysis)" persistent-hint
                variant="outlined" v-model="comVar.finalRent" suffix="CHF"></v-text-field> </v-col> </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title>Taxes and Fees (include 'with sale'?)</v-card-title>
          <v-row>
            <p class="ma-4 text-high-emphasis text-body-2"> These values can strongly affect outcomes. All additional
              money saved via differences in initial or recurring costs are assumed to be invested and growing
              at the rate set below. TODO make all of these columns?
            </p>
          </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2"><span
                class="font-weight-bold text-body-1 text-high-emphasis">Real Estate Sale Fees</span> are generally around
              4% of the sale price in most of Switzerland</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="" variant="outlined" v-model="initVar.realEstateFeeInput"
                suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Sale Price" variant="outlined" v-model="comVar.salePrice"
                suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Sale Fee" variant="outlined" v-model="comVar.realEstateFeeAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2"><span
                class="font-weight-bold text-body-1 text-high-emphasis">Property Capital Gains Tax Rate </span> differs by
              canton and by how long is spent living in the property - typically, the longer you stay, the less taxes are
              owed.</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Tax Rate" variant="outlined" v-model="initVar.gainsTaxInput"
                suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Capital Gain" variant="outlined" v-model="comVar.totalGain"
                suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Tax Paid" variant="outlined" v-model="comVar.gainsTaxAmount"
                suffix="CHF"></v-text-field> </v-col>
          </v-row>
        </v-card>

      </v-col>
      <v-col cols="3" no-gutters>
        <div class="mr-2" style="position: fixed; width: 100px top: 100px">
          <v-card class="ma-2 pa-2">
            <v-row>
              <v-col>
                <v-card-title class="mb-2">Buying Costs</v-card-title>
                <v-card-text> TODO should split into rent vs buy columns like NYT? Also TODO color code amounts red if
                  expense, green if revenue </v-card-text>
                <v-row> <v-col> <v-text-field readonly label="Initial Costs, Buy" variant="outlined" persistent-hint
                      hint="(Including Down Payment)" v-model="comVar.initTotal" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-row> <v-col> <v-text-field readonly label="Recurring Costs, Buy" variant="outlined"
                      v-model="comVar.recurringTotal" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Equity (Value Owned)" variant="outlined" persistent-hint
                      hint="(Including Down Payment)" v-model="comVar.equity" suffix="CHF"></v-text-field> </v-col>
                </v-row>
                <v-row> <v-col> <v-text-field readonly label="Selling Costs" variant="outlined"
                      v-model="comVar.sellingCostAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-card-text> TODO should I put a inline variable on this label like "after 'x' years"? </v-card-text>
                <v-row> <v-col> <v-text-field readonly label="Total Net Cost" variant="outlined"
                      v-model="comVar.netBuyAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
              </v-col>
              <v-col>
                <v-card-title class="mb-2">Renting Costs</v-card-title>
                <v-card-text> TODO color code amounts red if expense, green if revenue </v-card-text>
                <v-row> <v-col> <v-text-field readonly label="Total Rent Paid" variant="outlined"
                      v-model="comVar.totalRentPaid" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Investment Returns of Down Payment" variant="outlined"
                      v-model="comVar.investDown" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Investment Returns from Recurring Cost Delta"
                      variant="outlined" v-model="comVar.investRecurDelta" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-card-text> TODO make the net costs parallel under a subtotal line, and should I put a inline variable
                  on this label like "after 'x' years"? </v-card-text>
                <v-row> <v-col> <v-text-field color="primary" readonly label="Total Net Cost" variant="outlined"
                      v-model="comVar.netRentAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
              </v-col>
            </v-row>
          </v-card>
        </div>
      </v-col>

    </v-row>


  </v-container>
</template>
