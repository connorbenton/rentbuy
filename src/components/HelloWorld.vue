<script setup lang="ts">
import { ref, watch, reactive, computed, nextTick } from 'vue'
import { resourceLimits } from 'worker_threads';
import { vMaska } from 'maska'
import { reverse } from 'dns';
import { format } from 'path';


// Rules for evaluating form input
const rules = {
  down: (value: number) => (downTotalRaw.value / priceRaw.value >= 0.2 && downTotalRaw.value / priceRaw.value < 1) || 'Total Down payment must be at least 20 and not more than 100 percent',
  downOwn: (value: number) => (value >= 10 && value < 100) || 'Down payment own funds must be at least 10 percent',
  second: (value: number) => (value <= 15) || 'Amortization must happen within 15 years'
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
const priceInput = ref(1000000)
const downOwnInput = ref(10)
const downSecondInput = ref(10)
const mortgageRate = ref(2.5)
const secondMortgageAmortizationLength = ref(15)
const yearsInProperty = ref(15)
const upfrontCosts = ref(0)

const currOptions = { mask: ["#,###,###,###", "###,###,###", "##,###,###", "#,###,###", "###,###", "##,###", "#,###", "###", "##", "#"], reverse: true }
</script>

<template>
  <v-container>
    <v-row> <v-col> <v-text-field clearable label="Property Purchase Price" variant="outlined" v-maska:[currOptions]
          v-model="priceInput"></v-text-field> </v-col>
      <v-col> <v-text-field readonly variant="outlined" v-model="priceDisplay"></v-text-field> </v-col> </v-row>

    <v-form ref="form" validate-on="input">
      <v-row> <v-col> <v-text-field clearable label="Percent Down Payment from Own Funds + 3rd Pillar" variant="outlined"
            v-model="downOwnInput" suffix="%" :rules="[rules.downOwn]"></v-text-field> </v-col>
        <v-col> <v-text-field readonly label="Down Payment Amount" variant="outlined"
            v-model="downOwnDisplay"></v-text-field> </v-col> </v-row>
      <v-row> <v-col> <v-text-field clearable label="Percent Down Payment From 2nd Pillar" variant="outlined"
            hint="Total withdrawal only possible up to age 50" v-model="downSecondInput" suffix="%"
            :rules="[rules.down]"></v-text-field> </v-col>
        <v-col> <v-text-field readonly label="2nd Pillar Down Payment Amount" variant="outlined"
            v-model="downSecondDisplay"></v-text-field> </v-col> </v-row>
      <v-row> <v-col> <v-text-field readonly label="Percent Down Payment Total" variant="outlined"
            v-model="downTotalInput" suffix="%" :rules="[rules.down]"></v-text-field> </v-col>
        <v-col> <v-text-field readonly label="Down Payment Total Amount" variant="outlined"
            v-model="downTotalDisplay"></v-text-field> </v-col> </v-row>
    </v-form>

    <v-row> <v-col> <v-card text="Total Initial Mortgaged Amount"></v-card> </v-col>
      <v-col> <v-text-field readonly variant="outlined" v-model="initialMortgagedAmount"></v-text-field> </v-col> </v-row>
      
    <v-row> <v-col> <v-card text="Total First Mortgage amount (max 67% of purchase price)"></v-card> </v-col>
      <v-col> <v-text-field readonly variant="outlined" v-model="initialFirstAmount"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Total Second Mortgage amount (max 13% of purchase price)"></v-card> </v-col>
      <v-col> <v-text-field readonly variant="outlined" v-model="initialSecondAmount"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Mortgage Interest Rate"></v-card> </v-col>
      <v-col> <v-text-field variant="outlined" v-model="mortgageRate" suffix="%"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Years to Second Mortgage Amortization"></v-card> </v-col>
      <v-col> <v-text-field variant="outlined" :rules="[rules.second]" v-model="secondMortgageAmortizationLength"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Years for Analysis"></v-card> </v-col>
      <v-col> <v-text-field variant="outlined" label="(Total Years Living In Property vs. Renting)" v-model="yearsInProperty"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Upfront Costs"></v-card> </v-col>
      <v-col> <v-text-field variant="outlined" label="(Notary/registration fees, property transfer tax, etc.)" v-model="upfrontCosts"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Total First Mortgage Monthly Payments"></v-card> </v-col>
      <v-col> <v-text-field readonly variant="outlined" v-model="firstMonthly"></v-text-field> </v-col> </v-row>

    <v-row> <v-col> <v-card text="Total Second Mortgage Monthly Payments"></v-card> </v-col>
      <v-col> <v-text-field readonly variant="outlined" v-model="secondMonthly"></v-text-field> </v-col> </v-row>

  </v-container>
</template>
