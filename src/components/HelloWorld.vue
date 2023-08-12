<script setup lang="ts">
import { ref, watch, reactive, computed, nextTick } from 'vue'
import { resourceLimits } from 'worker_threads';
import { vMaska } from 'maska'
import { reverse } from 'dns';
import { format } from 'path';


// Rules for evaluating form input
const rules = {
  down: (value: number) => (rawVariables.downTotalRaw.value / rawVariables.priceRaw.value >= 0.2 && rawVariables.downTotalRaw.value / rawVariables.priceRaw.value < 1) || 'Total Down payment must be at least 20 and not more than 100 percent',
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
//   console.log(rawVariables.downTotalRaw.value) // 0

//   // DOM is now updated
//   console.log(rawVariables.downTotalRaw.value) // 1
// }



//Raw variables for computations
const rawVariables = reactive({
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
  () => rawVariables.downTotalRaw, (value) => {
    // console.log(form.value)
    if (form.value != undefined) form.value.validate()
    // console.log(`total down is: ${value}`)
  })

async function validate() {
  const { valid } = await form.value.validate()

  if (valid) alert('Form is valid')
}
// Computed variables 
const computedVariables = computed ()
const priceDisplay = computed(() => {
  rawVariables.priceRaw= parseInt(initialValues.priceInput.toString().replace(/,/g, ''), 10);
  return rawVariables.priceRaw.toLocaleString();
})
const downOwnDisplay = computed(() => {
  rawVariables.downOwnRaw= Number(priceDisplay.value);
  rawVariables.downOwnRaw= (initialValues.downOwnInput / 100 * rawVariables.priceRaw);
  return rawVariables.downOwnRaw.toLocaleString();
})
const downSecondDisplay = computed(() => {
  rawVariables.downSecondRaw= (initialValues.downSecondInput / 100 * rawVariables.priceRaw);
  return rawVariables.downSecondRaw.toLocaleString();
})
const downTotalInput = computed(() => { return parseInt(initialValues.downSecondInput.toString()) + parseInt(initialValues.downOwnInput.toString()) })
const downTotalDisplay = computed(() => {
  rawVariables.downTotalRaw= (rawVariables.downOwnRaw+ rawVariables.downSecondRaw);
  return rawVariables.downTotalRaw.toLocaleString();
})
const mortgageRateRaw = computed(() => {
  return Number(initialValues.mortgageRateInput);
})
const initialMortgagedAmount = computed(() => {
  rawVariables.initialMortgageRaw= (rawVariables.priceRaw- rawVariables.downTotalRaw);
  return rawVariables.initialMortgageRaw.toLocaleString();
})
const initialFirstAmount = computed(() => {
  rawVariables.initialFirstRaw= (Math.min(rawVariables.initialMortgageRaw, rawVariables.priceRaw* 0.67));
  return rawVariables.initialFirstRaw.toLocaleString();
})
const initialSecondAmount = computed(() => {
  rawVariables.initialSecondRaw= (Math.max(rawVariables.initialMortgageRaw- rawVariables.initialFirstRaw, 0));
  return rawVariables.initialSecondRaw.toLocaleString();
})
const firstMonthly = computed(() => {
  rawVariables.firstMonthlyRaw= (Math.max(rawVariables.initialMortgageRaw- rawVariables.initialFirstRaw, 0));
  return rawVariables.firstMonthlyRaw.toLocaleString();
})
const secondMonthly = computed(() => {
  rawVariables.secondMonthlyRaw= (Math.max(rawVariables.initialMortgageRaw- rawVariables.initialFirstRaw, 0));
  return rawVariables.secondMonthlyRaw.toLocaleString();
})
const upfrontCostsAmount = computed(() => {
  rawVariables.upfrontCostsRaw= (initialValues.upfrontCostsInput / 100 * rawVariables.priceRaw);
  return rawVariables.upfrontCostsRaw.toLocaleString();
})
const maintAmount = computed(() => {
  rawVariables.maintRaw= (initialValues.maintInput / 100 * rawVariables.priceRaw);
  return rawVariables.maintRaw.toLocaleString();
})
const marginalAmount = computed(() => {
  rawVariables.marginalRaw= (initialValues.marginalInput / 100 * (rawVariables.eigenRaw - rawVariables.maintRaw - rawVariables.firstInterestRaw - rawVariables.secondInterestRaw));
  return rawVariables.marginalRaw.toLocaleString();
})
const marginalOnlyFirstAmount = computed(() => {
  rawVariables.marginalOnlyFirstRaw = (initialValues.marginalInput / 100 * (rawVariables.eigenRaw - rawVariables.maintRaw - rawVariables.firstInterestRaw));
  return rawVariables.marginalOnlyFirstRaw.toLocaleString();
})
const eigenAmount = computed(() => {
  rawVariables.eigenRaw = (initialValues.eigenInput / 100 * .0425 * rawVariables.priceRaw);
  return rawVariables.eigenRaw.toLocaleString();
})
const propTaxAmount = computed(() => {
  rawVariables.marginalRaw = (initialValues.marginalInput / 100 * rawVariables.priceRaw);
  return rawVariables.propTaxRaw.toLocaleString();
})
const firstInterest = computed(() => {
  rawVariables.firstInterestRaw = (mortgageRateRaw / 100 * rawVariables.initialFirstRaw);
  return rawVariables.firstInterestRaw.toLocaleString();
})
const secondInterest = computed(() => {
  rawVariables.secondInterestRaw = ((mortgageRateRaw + secondPremiumRaw) / 100 * rawVariables.initialSecondRaw);
  return rawVariables.secondInterestRaw.toLocaleString();
})
const secondLengthRaw = computed(() => {
  return Number(initialValues.secondMortgageAmortizationLength);
})
const secondAmortisation = computed(() => {
  rawVariables.secondAmortisationRaw = (rawVariables.initialSecondRaw / secondLengthRaw);
  return Math.round(rawVariables.secondAmortisationRaw).toLocaleString();
})
const investRaw = computed(() => {
  return Number(initialValues.investInput);
})
const houseRateRaw = computed(() => {
  return Number(initialValues.houseRateInput);
})
const rentRateRaw = computed(() => {
  return Number(initialValues.rentRateInput);
})
const finalRent = computed(() => {
  return Math.round((rawVariables.finalRentRaw)).toLocaleString();
})
const totalRentPaid = computed(() => {
  rawVariables.rentRaw = parseInt(initialValues.rentInput.toString().replace(/,/g, ''), 10);
  var x = 0;
  var currentYearRent = rawVariables.rentRaw;
  for (var i = 0; i < yearsTotalRaw; i++) {
    x = x + currentYearRent * 12;
    currentYearRent = currentYearRent * (1 + Number(rentRateRaw) / 100);
    rawVariables.finalRentRaw = currentYearRent;
  }
  rawVariables.totalRentPaidRaw = x;
  return Math.round((rawVariables.totalRentPaidRaw)).toLocaleString();
})

const investDown = computed(() => {
  var x = rawVariables.downOwnRaw;
  for (var i = 0; i < yearsTotalRaw; i++) {
    x = x * (1 + Number(investRaw) / 100);
  }
  rawVariables.investDownRaw = x;
  return Math.round((rawVariables.investDownRaw)).toLocaleString();
})

const investRecurDelta = computed(() => {
  rawVariables.rentRaw = parseInt(initialValues.rentInput.toString().replace(/,/g, ''), 10);
  var x = 0;
  var currentYearRent = rawVariables.rentRaw;
  for (var i = 0; i < yearsTotalRaw; i++) {
    if (i < secondLengthRaw) {
      var diffCost = recurringYearlyCostBeforeSecondDone - (currentYearRent * 12);
    } else {
      var diffCost = recurringYearlyCostAfterSecondDone - (currentYearRent * 12);
    }
    x = x + diffCost;
    x = x * (1 + Number(investRaw) / 100);
    currentYearRent = currentYearRent * (1 + Number(rentRateRaw) / 100);
  }
  rawVariables.investRecurDeltaRaw = x;
  return Math.round((rawVariables.investRecurDeltaRaw)).toLocaleString();
})

const yearsTotalRaw = computed(() => {
  return Number(initialValues.yearsInProperty);
})
const secondPremiumRaw = computed(() => {
  return Number(initialValues.secondPremiumInput);
})

const salePrice = computed(() => {
  rawVariables.salePriceRaw = Math.round((rawVariables.priceRaw * ((houseRateRaw / 100 + 1) ** yearsTotalRaw)));
  return rawVariables.salePriceRaw.toLocaleString();
})
const realEstateFeeAmount = computed(() => {
  rawVariables.realEstateFeeAmountRaw = rawVariables.salePriceRaw * (initialValues.realEstateFeeInput / 100);
  return Math.round(rawVariables.realEstateFeeAmountRaw).toLocaleString();
})
const totalGain = computed(() => {
  rawVariables.totalGainRaw = rawVariables.salePriceRaw - rawVariables.priceRaw;
  return rawVariables.totalGainRaw.toLocaleString();
})
const gainsTaxAmount = computed(() => {
  rawVariables.gainsTaxRaw = Math.round(rawVariables.totalGainRaw * (initialValues.gainsTaxInput / 100));
  return rawVariables.gainsTaxRaw.toLocaleString();
})

const initTotal = computed(() => {
  rawVariables.initTotalRaw = (rawVariables.downTotalRaw + rawVariables.upfrontCostsRaw);
  return Math.round(rawVariables.initTotalRaw).toLocaleString();
})

const recurringYearlyCostBeforeSecondDone = computed(() => {
  return (rawVariables.maintRaw + rawVariables.secondAmortisationRaw + rawVariables.secondInterestRaw + rawVariables.firstInterestRaw + rawVariables.marginalRaw);
})

const recurringYearlyCostAfterSecondDone = computed(() => {
  return (rawVariables.firstInterestRaw + rawVariables.maintRaw + rawVariables.marginalOnlyFirstRaw);
})

const recurringTotal = computed(() => {
  if (yearsTotalRaw > secondLengthRaw) {
    rawVariables.recurringTotalRaw = secondLengthRaw * recurringYearlyCostBeforeSecondDone + (yearsTotalRaw - secondLengthRaw) * recurringYearlyCostAfterSecondDone;
  } else {
    rawVariables.recurringTotalRaw = yearsTotalRaw * recurringYearlyCostBeforeSecondDone;
  }
  return Math.round(rawVariables.recurringTotalRaw).toLocaleString();
})
const equity = computed(() => {
  rawVariables.equityRaw = (rawVariables.totalGainRaw + rawVariables.downTotalRaw + Math.min(initialValues.secondMortgageAmortizationLength, yearsTotalRaw) * rawVariables.secondAmortisationRaw);
  return Math.round(rawVariables.equityRaw).toLocaleString();
})
const sellingCostAmount = computed(() => {
  rawVariables.sellingCostRaw = (rawVariables.gainsTaxRaw + rawVariables.realEstateFeeAmountRaw);
  return Math.round(rawVariables.sellingCostRaw).toLocaleString();
})
const netBuyAmount = computed(() => {
  rawVariables.netBuyRaw = (rawVariables.initTotalRaw + rawVariables.recurringTotalRaw - rawVariables.equityRaw + rawVariables.sellingCostRaw);
  return Math.round(rawVariables.netBuyRaw).toLocaleString();
})
const netRentAmount = computed(() => {
  rawVariables.netRentRaw = (rawVariables.totalRentPaidRaw - rawVariables.investDownRaw - rawVariables.investRecurDeltaRaw);
  return Math.round(rawVariables.netRentRaw).toLocaleString();
})

const initialValues = reactive({
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
    <v-row>
      <v-col>
        <v-card class="mx-2 px-4">
          <v-card-title> Property Purchase Price vs. Property Rent</v-card-title>
          <v-row class="pt-2"> <v-col> <v-text-field clearable label="Enter Purchase Price" variant="outlined"
                v-maska:[currOptions] v-model="initialValues.priceInput" suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field clearable label="Enter Rent Per Month" variant="outlined" v-maska:[currOptions]
                v-model="initialValues.rentInput" suffix="CHF"></v-text-field> </v-col>
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
                v-model="initialValues.yearsInProperty" :rules="[rules.positiveInteger]"></v-text-field> </v-col>
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
                  v-model="initialValues.downOwnInput" suffix="%" :rules="[rules.downOwn]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="Own Funds Down Amount" variant="outlined"
                  v-model="downOwnDisplay"></v-text-field> </v-col> </v-row>
            <v-row> <v-col> <v-text-field clearable label="% Down from 2nd Pillar" variant="outlined"
                  hint="Total withdrawal only possible up to age 50" v-model="initialValues.downSecondInput" suffix="%"
                  :rules="[rules.down]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="2nd Pillar Down Amount" variant="outlined"
                  v-model="downSecondDisplay"></v-text-field> </v-col> </v-row>
            <v-row> <v-col> <v-text-field readonly label="Percent Down Payment Total" variant="outlined"
                  v-model="downTotalInput" suffix="%" :rules="[rules.down]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="Down Payment Total Amount" variant="outlined"
                  v-model="downTotalDisplay"></v-text-field> </v-col> </v-row>
          </v-card>
        </v-form>

        <v-card class="ma-2 pa-2">
          <v-card-title> Mortgage Details </v-card-title>
          <v-card-text>
            test
          </v-card-text>

          <v-row> <v-col> <v-card text="Mortgage Interest Rate"></v-card> </v-col>
            <v-col> <v-text-field label="TODO DONE add number check rule" variant="outlined"
                v-model="initialValues.mortgageRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Years to Second Mortgage Amortization"></v-card> </v-col>
            <v-col> <v-text-field variant="outlined" label="TODO DONE make rules check force this as int"
                :rules="[rules.second]" v-model="initialValues.secondMortgageAmortizationLength"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total Initial Mortgaged Amount"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="initialMortgagedAmount"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total First Mortgage amount (max 67% of purchase price)"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="initialFirstAmount"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="First Mortgage, Interest per Year"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="firstInterest"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Total Second Mortgage amount (max 13% of purchase price)"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="initialSecondAmount"></v-text-field> </v-col>
          </v-row>

          <v-row> <v-col> <v-card text="Second Mortgage, Amortisation per Year"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="secondAmortisation"></v-text-field> </v-col>
          </v-row>

          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">The second mortgage typically carries a premium of 0.5-1%
              above the first mortgage interest rate. </p>
          </v-row>
          <v-row>
            <v-col> <v-text-field clearable label="% Premium" variant="outlined"
                v-model="initialValues.secondPremiumInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <!-- <v-col> <v-card text="Second Mortgage, Interest per Year"></v-card> </v-col> -->
            <v-col> <v-text-field readonly label="Second Mortgage, Interest per Year" variant="outlined"
                v-model="secondInterest"></v-text-field> </v-col>
          </v-row>
          <v-row> <v-col> <v-card text="Total First Mortgage Monthly Payments"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="firstMonthly"></v-text-field> </v-col> </v-row>

          <v-row> <v-col> <v-card text="Total Second Mortgage Monthly Payments"></v-card> </v-col>
            <v-col> <v-text-field readonly variant="outlined" v-model="secondMonthly"></v-text-field> </v-col> </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title> Upfront Costs</v-card-title>
          <v-card-text>
            This can differ sharply by canton - includes notary/registration fees, property transfer tax, etc.
          </v-card-text>
          <v-row> <v-col> <v-text-field clearable label="Costs as % of Purchase Price" variant="outlined"
                v-model="initialValues.upfrontCostsInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Upfront Costs Amount" variant="outlined" v-model="upfrontCostsAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
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
                v-model="initialValues.maintInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined" v-model="maintAmount"
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
                v-model="initialValues.marginalInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Extra Income Tax Per Year" persistent-hint hint="(1st+2nd Mortgages)"
                variant="outlined" v-model="marginalAmount" suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field readonly persistent-hint hint="(1st Mortgage Only)" variant="outlined"
                v-model="marginalOnlyFirstAmount" suffix="CHF"></v-text-field> </v-col>
          </v-row>

          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">Eigenmietwert is often calculated from a fraction of the
              actual purchase price. TODO add an expander to hide the next rows under imputed rental value?</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Eigenmietwert Value as % of Price - TODO make slider?"
                variant="outlined" v-model="initialValues.eigenInput" suffix="%" :rules="[rules.number]"></v-text-field>
            </v-col>
            <v-col> <v-text-field readonly label="Eigenmietwert Income per Year" variant="outlined" v-model="eigenAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
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
                v-model="initialValues.propTaxInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Property Tax Per Year" variant="outlined" v-model="propTaxAmount"
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
                v-model="initialValues.investInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined" v-model="maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">*Property Price Growth Rate* (TODO bold) is typically 1-1.5%
              in urban areas of Switzerland over the last 50 years</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Growth Rate, Per Year" variant="outlined"
                v-model="initialValues.houseRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Final Property Value" variant="outlined" v-model="maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2">*Rental Price Growth Rate* (TODO bold) is typically coupled
              to both property price growth rates and interest rates, but can differ over time</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Growth Rate, Per Year" variant="outlined"
                v-model="initialValues.rentRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Final Monthly Rent" hint="(In Final Year Of Analysis)" persistent-hint
                variant="outlined" v-model="finalRent" suffix="CHF"></v-text-field> </v-col> </v-row>
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
          <v-row> <v-col> <v-text-field clearable label="" variant="outlined" v-model="initialValues.realEstateFeeInput"
                suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Sale Price" variant="outlined" v-model="salePrice"
                suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Sale Fee" variant="outlined" v-model="realEstateFeeAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>
            <p class="mx-4 text-medium-emphasis text-body-2"><span
                class="font-weight-bold text-body-1 text-high-emphasis">Property Capital Gains Tax Rate </span> differs by
              canton and by how long is spent living in the property - typically, the longer you stay, the less taxes are
              owed.</p>
          </v-row>
          <v-row> <v-col> <v-text-field clearable label="Tax Rate" variant="outlined"
                v-model="initialValues.gainsTaxInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Capital Gain" variant="outlined" v-model="totalGain"
                suffix="CHF"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Tax Paid" variant="outlined" v-model="gainsTaxAmount"
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
                      hint="(Including Down Payment)" v-model="initTotal" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Recurring Costs, Buy" variant="outlined"
                      v-model="recurringTotal" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Equity (Value Owned)" variant="outlined" persistent-hint
                      hint="(Including Down Payment)" v-model="equity" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Selling Costs" variant="outlined"
                      v-model="sellingCostAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-card-text> TODO should I put a inline variable on this label like "after 'x' years"? </v-card-text>
                <v-row> <v-col> <v-text-field readonly label="Total Net Cost" variant="outlined" v-model="netBuyAmount"
                      suffix="CHF"></v-text-field> </v-col> </v-row>
              </v-col>
              <v-col>
                <v-card-title class="mb-2">Renting Costs</v-card-title>
                <v-card-text> TODO color code amounts red if expense, green if revenue </v-card-text>
                <v-row> <v-col> <v-text-field readonly label="Total Rent Paid" variant="outlined" v-model="totalRentPaid"
                      suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Investment Returns of Down Payment" variant="outlined"
                      v-model="investDown" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-row> <v-col> <v-text-field readonly label="Investment Returns from Recurring Cost Delta"
                      variant="outlined" v-model="investRecurDelta" suffix="CHF"></v-text-field> </v-col> </v-row>
                <v-card-text> TODO make the net costs parallel under a subtotal line, and should I put a inline variable
                  on this label like "after 'x' years"? </v-card-text>
                <v-row> <v-col> <v-text-field color="primary" readonly label="Total Net Cost" variant="outlined"
                      v-model="netRentAmount" suffix="CHF"></v-text-field> </v-col> </v-row>
              </v-col>
            </v-row>
          </v-card>
        </div>
      </v-col>

    </v-row>


</v-container></template>
