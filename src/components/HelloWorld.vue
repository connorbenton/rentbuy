<script setup lang="ts">
import { ref, watch, reactive, computed, nextTick } from 'vue'
import { resourceLimits } from 'worker_threads';
import { vMaska } from 'maska'
import { reverse } from 'dns';
import { format } from 'path';


// Rules for evaluating form input
const rules = {
  down: (value: number) => (downTotalRaw.value / priceRaw.value >= 0.2 && downTotalRaw.value / priceRaw.value < 1) || 'Total Down payment must be at least 20 and not more than 100 percent',
  downOwn: (value: number) => (Number(value) >= 10 && Number(value) < 100) || 'Down payment own funds must be at least 10 percent',
  second: (value: number) => (Number(value) <= 15 && Number(value) > 0) || 'Amortization must happen within 15 years',
  positiveInteger: (value: number) => (Number.isInteger(Number(value)) && Number(value) > 0) || 'Value must be a positive integer',
  number: (value: string) => (Number.isFinite(Number(value)) && value !="" ) || 'Value must be a number'
}

const form = ref()
// form.value = true

// const count = ref(0)

// async function increment() {
//   count.value++

//   // DOM not yet updated
//   console.log(downTotalRaw.value) // 0

//   // DOM is now updated
//   console.log(downTotalRaw.value) // 1
// }



//Raw variables for computations
var priceRaw = reactive({ value: 0 })
var downTotalRaw = reactive({ value: 0 })
var downOwnRaw = reactive({ value: 0 })
var downSecondRaw = reactive({ value: 0 })
var initialMortgageRaw = reactive({ value: 0 })
var initialFirstRaw = reactive({ value: 0 })
var initialSecondRaw = reactive({ value: 0 })
var firstMonthlyRaw = reactive({ value: 0 })
var secondMonthlyRaw = reactive({ value: 0 })
var upfrontCostsRaw = reactive({ value: 0 })
var maintRaw = reactive({ value: 0 })
var marginalRaw = reactive({ value: 0 })
var marginalOnlyFirstRaw = reactive({ value: 0 })
var eigenRaw = reactive({ value: 0 })
var propTaxRaw = reactive({ value: 0 })
var firstInterestRaw = reactive({ value: 0 })
var secondInterestRaw = reactive({ value: 0 })
var secondAmortisationRaw = reactive({ value: 0 })
var initTotalRaw = reactive({ value: 0 })
var recurringTotalRaw = reactive({ value: 0 })
var equityRaw = reactive({ value: 0 })
var netBuyRaw = reactive({ value: 0 })

watch(
  () => downTotalRaw.value, (value) => {
    // console.log(form.value)
    if (form.value != undefined) form.value.validate()
    // console.log(`total down is: ${value}`)
  })

async function validate() {
  const { valid } = await form.value.validate()

  if (valid) alert('Form is valid')
}
// Computed variables 
const priceDisplay = computed(() => {
  priceRaw.value = parseInt(priceInput.value.toString().replace(/,/g, ''), 10);
  return priceRaw.value.toLocaleString();
})
const downOwnDisplay = computed(() => {
  downOwnRaw.value = (downOwnInput.value / 100 * priceRaw.value);
  return downOwnRaw.value.toLocaleString();
})
const downSecondDisplay = computed(() => {
  downSecondRaw.value = (downSecondInput.value / 100 * priceRaw.value);
  return downSecondRaw.value.toLocaleString();
})
const downTotalInput = computed(() => { return parseInt(downSecondInput.value.toString()) + parseInt(downOwnInput.value.toString()) })
const downTotalDisplay = computed(() => {
  downTotalRaw.value = (downOwnRaw.value + downSecondRaw.value);
  return downTotalRaw.value.toLocaleString();
})
const mortgageRateRaw = computed(() => {
  return Number(mortgageRateInput.value);
})
const initialMortgagedAmount = computed(() => {
  initialMortgageRaw.value = (priceRaw.value - downTotalRaw.value);
  return initialMortgageRaw.value.toLocaleString();
})
const initialFirstAmount = computed(() => {
  initialFirstRaw.value = (Math.min(initialMortgageRaw.value, priceRaw.value * 0.67));
  return initialFirstRaw.value.toLocaleString();
})
const initialSecondAmount = computed(() => {
  initialSecondRaw.value = (Math.max(initialMortgageRaw.value - initialFirstRaw.value, 0));
  return initialSecondRaw.value.toLocaleString();
})
const firstMonthly = computed(() => {
  firstMonthlyRaw.value = (Math.max(initialMortgageRaw.value - initialFirstRaw.value, 0));
  return firstMonthlyRaw.value.toLocaleString();
})
const secondMonthly = computed(() => {
  secondMonthlyRaw.value = (Math.max(initialMortgageRaw.value - initialFirstRaw.value, 0));
  return secondMonthlyRaw.value.toLocaleString();
})
const upfrontCostsAmount = computed(() => {
  upfrontCostsRaw.value = (upfrontCostsInput.value / 100 * priceRaw.value);
  return upfrontCostsRaw.value.toLocaleString();
})
const maintAmount = computed(() => {
  maintRaw.value = (maintInput.value / 100 * priceRaw.value);
  return maintRaw.value.toLocaleString();
})
const marginalAmount = computed(() => {
  marginalRaw.value = (marginalInput.value / 100 * (eigenRaw.value - maintRaw.value - firstInterestRaw.value - secondInterestRaw.value));
  return marginalRaw.value.toLocaleString();
})
const marginalOnlyFirstAmount = computed(() => {
  marginalOnlyFirstRaw.value = (marginalInput.value / 100 * (eigenRaw.value - maintRaw.value - firstInterestRaw.value));
  return marginalOnlyFirstRaw.value.toLocaleString();
})
const eigenAmount = computed(() => {
  eigenRaw.value = (eigenInput.value / 100 * .0425 * priceRaw.value);
  return eigenRaw.value.toLocaleString();
})
const propTaxAmount = computed(() => {
  marginalRaw.value = (marginalInput.value / 100 * priceRaw.value);
  return propTaxRaw.value.toLocaleString();
})
const firstInterest = computed(() => {
  firstInterestRaw.value = (mortgageRateRaw.value / 100 * initialFirstRaw.value);
  return firstInterestRaw.value.toLocaleString();
})
const secondInterest = computed(() => {
  secondInterestRaw.value = ((mortgageRateRaw.value + secondPremiumRaw.value) / 100 * initialSecondRaw.value);
  return secondInterestRaw.value.toLocaleString();
})
const secondLengthRaw = computed(() => {
  return Number(secondMortgageAmortizationLength.value);
})
const secondAmortisation = computed(() => {
  secondAmortisationRaw.value = (initialSecondRaw.value / secondLengthRaw.value);
  return secondAmortisationRaw.value.toLocaleString();
})
const investRaw = computed(() => {
  return Number(investInput.value);
})
const houseRateRaw = computed(() => {
  return Number(houseRateInput.value);
})
const rentRateRaw = computed(() => {
  return Number(rentRateInput.value);
})
const secondPremiumRaw = computed(() => {
  return Number(secondPremiumInput.value);
})
const initTotal = computed(() => {
  initTotalRaw.value = (upfrontCostsRaw.value);
  return initTotalRaw.value.toLocaleString();
})
const recurringTotal = computed(() => {
  recurringTotalRaw.value = (4);
  return recurringTotalRaw.value.toLocaleString();
})
const equity = computed(() => {
  equityRaw.value = (initialSecondRaw.value / secondLengthRaw.value);
  return equityRaw.value.toLocaleString();
})
var priceInput = ref(1000000)
var downOwnInput = ref(10)
var downSecondInput = ref(10)
var mortgageRateInput = ref(2.5)
var secondMortgageAmortizationLength = ref(15)
var yearsInProperty = ref(15)
var upfrontCostsInput = ref(0.5)
var maintInput = ref(0.75)
var marginalInput = ref(35)
var eigenInput = ref(70)
var propTaxInput = ref(0)
var investInput = ref(7)
var houseRateInput = ref(1)
var rentRateInput = ref(0.5)
var secondPremiumInput = ref(1)


const currOptions = { mask: ["#,###,###,###", "###,###,###", "##,###,###", "#,###,###", "###,###", "##,###", "#,###", "###", "##", "#"], reverse: true }
</script>

<template>
  <v-container>
    <v-row>
      <v-col>
        <v-card class="mx-2 px-4">
          <v-card-title> House Purchase Price </v-card-title>
          <v-card-text>
            placeholder text
          </v-card-text>
          <v-row class="pt-2"> <v-col> <v-text-field clearable label="Enter Purchase Price" variant="outlined"
                v-maska:[currOptions] v-model="priceInput"></v-text-field> </v-col>
            <v-col> <v-text-field readonly suffix="CHF" label="Purchase Total Amount" variant="outlined" v-model="priceDisplay"></v-text-field> </v-col>
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
                v-model="yearsInProperty" :rules="[rules.positiveInteger]"></v-text-field> </v-col>
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
                  v-model="downOwnInput" suffix="%" :rules="[rules.downOwn]"></v-text-field> </v-col>
              <v-col> <v-text-field readonly label="Own Funds Down Amount" variant="outlined"
                  v-model="downOwnDisplay"></v-text-field> </v-col> </v-row>
            <v-row> <v-col> <v-text-field clearable label="% Down from 2nd Pillar" variant="outlined"
                  hint="Total withdrawal only possible up to age 50" v-model="downSecondInput" suffix="%"
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
            <v-col> <v-text-field label="TODO DONE add number check rule" variant="outlined" v-model="mortgageRateInput"
                suffix="%" :rules="[rules.number]"></v-text-field> </v-col> </v-row>

          <v-row> <v-col> <v-card text="Years to Second Mortgage Amortization"></v-card> </v-col>
            <v-col> <v-text-field variant="outlined" label="TODO DONE make rules check force this as int"
                :rules="[rules.second]" v-model="secondMortgageAmortizationLength"></v-text-field> </v-col> </v-row>

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

          <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">The second mortgage typically carries a premium of 0.5-1% above the first mortgage interest rate. </p> </v-row>
          <v-row> 
           <v-col> <v-text-field clearable label="% Premium" variant="outlined"
                v-model="secondPremiumInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <!-- <v-col> <v-card text="Second Mortgage, Interest per Year"></v-card> </v-col> -->
            <v-col> <v-text-field readonly label="Second Mortgage, Interest per Year" variant="outlined" v-model="secondInterest"></v-text-field> </v-col>
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
            TODO add upfront percentage rules to percentage input box
          </v-card-text>
          <v-row> <v-col> <v-text-field clearable label="Costs as % of Purchase Price" variant="outlined"
                v-model="upfrontCostsInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Upfront Costs Amount" variant="outlined" v-model="upfrontCostsAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title> Annual Non-Mortgage Costs</v-card-title>
          <v-card-text>
          </v-card-text>
          <v-row> <p class="mx-4 mb-4 text-high-emphasis text-body-2"> Annual recurring costs include taxes, maintenance, insurance, etc. </p> </v-row>
          <v-row>  <p class="mx-4 text-medium-emphasis text-body-2"><span class="font-weight-bold text-body-1 text-high-emphasis"> Maintenance</span> per year is usually between 0.5 and 1% of purchase price  </p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="% of Purchase Price" variant="outlined"
                v-model="maintInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined" v-model="maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>

          <v-row> <p class="mx-4 text-medium-emphasis text-body-2"> Imputed rental value, or Eigenmietwert, is counted as additional income for personal taxes.
            However, mortgage interest and maintenance can be deducted in order to offset this additional income. TODO deductions offset income, not tax directly 
            Also check v-text-field label overflow
          </p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="Marginal Income Tax Rate" variant="outlined"
                v-model="marginalInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Extra Income Tax Per Year (1st+2nd Mortgages)" variant="outlined" v-model="marginalAmount"
                suffix="CHF"></v-text-field> </v-col> 
            <v-col> <v-text-field readonly label="(1st Mortgage Only)" variant="outlined" v-model="marginalOnlyFirstAmount"
                suffix="CHF"></v-text-field> </v-col> 
              </v-row>

          <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">Eigenmietwert is often calculated from a fraction of the actual purchase price. TODO add an expander to hide the next rows under imputed rental value?</p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="Eigenmietwert Value as % of Price - TODO make slider?" variant="outlined"
                v-model="eigenInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Eigenmietwert Income per Year" variant="outlined" v-model="eigenAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <!-- <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">TODO move this row to Mortgage section, also figure out how to fit all label text inside text-field</p> </v-row>
          <v-row> <v-col> <v-text-field readonly label="Mortgage Interest Per Year" ></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="First Mortgage" variant="outlined" v-model="firstInterest" suffix="CHF"></v-text-field> </v-col> 
            <v-col> <v-text-field readonly label="Second Mortgage" variant="outlined" v-model="secondInterest" suffix="CHF"></v-text-field> </v-col> 
          </v-row> -->

          <v-row> <p class="mx-4 text-medium-emphasis text-body-2"> Property Tax only exists in some cantons, and is levied at a percentage of the purchase price.</p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="% of Purchase Price" variant="outlined"
                v-model="propTaxInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Property Tax Per Year" variant="outlined" v-model="propTaxAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
        </v-card>

        <v-card class="ma-2 pa-2">
          <v-card-title>Assumptions for the Future</v-card-title>
          <v-row> <p class="ma-4 text-high-emphasis text-body-2"> These values can strongly affect outcomes. All additional money saved via differences in initial or recurring costs are assumed to be invested and growing
            at the rate set below. TODO make all of these columns?
          </p> </v-row>
          <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">*Average Real Investment Return Rate* (TODO bold) over the last century is around 7% for global equities, lower for various fixed-income portfolios</p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="Return Rate" variant="outlined"
                v-model="investInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Maintenance per Year" variant="outlined" v-model="maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">*Property Price Growth Rate* (TODO bold) is typically 1-1.5% in urban areas of Switzerland over the last 50 years</p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="Growth Rate" variant="outlined"
                v-model="houseRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Final Property Value" variant="outlined" v-model="maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row>  <p class="mx-4 text-medium-emphasis text-body-2">*Rental Price Growth Rate* (TODO bold) is typically coupled to both property price growth rates and interest rates, but can differ over time</p> </v-row>
          <v-row> <v-col> <v-text-field clearable label="Growth Rate" variant="outlined"
                v-model="rentRateInput" suffix="%" :rules="[rules.number]"></v-text-field> </v-col>
            <v-col> <v-text-field readonly label="Average Rent Per Month Analysis" variant="outlined" v-model="maintAmount"
                suffix="CHF"></v-text-field> </v-col> </v-row>
            </v-card>

      </v-col>
      <v-col cols="3" no-gutters>
        <div class="mr-2" style="position: fixed; width: 100px top: 100px">
        <v-card class="ma-2 pa-2">
          <v-card-title class="mb-2">Costs</v-card-title>
          <v-card-text> TODO should split into rent vs buy columns like NYT? </v-card-text>
          <v-row> <v-col> <v-text-field readonly label="Initial Costs, Buy" variant="outlined" v-model="initTotal"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row> <v-col> <v-text-field readonly label="Recurring Costs, Buy" variant="outlined" v-model="recurringTotal"
                suffix="CHF"></v-text-field> </v-col> </v-row>
          <v-row> <v-col> <v-text-field readonly label="Equity (Value Owned)" variant="outlined" v-model="equity"
                suffix="CHF"></v-text-field> </v-col> </v-row>
        </v-card>
        </div>
      </v-col>

    </v-row>


</v-container></template>
