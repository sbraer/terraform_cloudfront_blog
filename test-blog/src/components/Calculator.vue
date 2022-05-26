<template>
<div class="container">
  <h1 class="text-center">Simple calculator</h1>
<div class="row">
    <div class="col-2 offset-1">
      <img alt="Vue logo" src="../assets/logo.png" class="img-fluid" />
    </div>
    <div class="col-6">
      <div class="row">
        <form>
          <div class="form-group">
            <label for="number1">First Number</label>
            <input type="number" class="form-control" id="number1" placeholder="Enter first number" v-model="Number1Input">
            <div class="alert alert-danger" role="alert" v-if="showErrorNumber1">
              Insert a valid integer number!
            </div>
          </div>
          <div class="form-group form-vertical-space">
            <label for="number2">Second Number</label>
            <input type="number" class="form-control" id="number2" placeholder="Enter second number" v-model="Number2Input">
            <div class="alert alert-danger" role="alert" v-if="showErrorNumber2">
              Insert a valid integer number!
            </div>
          </div>
          <div class="form-vertical-space">
            <button type="button" class="btn btn-primary" @click="SumLocally">Sum locally</button>
            <button type="button" class="btn btn-danger" @click="SumRemotely" :disabled="showErrorExternalUrl">Sum remotely</button>
          </div>
          <div class="alert alert-danger" role="alert" v-if="showErrorExternalUrl">
            External url is not definied
          </div>

        </form>
      </div>
    </div>
  </div>

  <!-- Modal -->
<div v-if="showModal">
    <transition name="modal">
      <div class="modal-mask">
        <div class="modal-wrapper">
          <div class="modal-dialog" role="document">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">Result</h5>
              </div>
              <div class="modal-body">
                <p>{{ Number1Input}} + {{Number2Input}} = {{Result}}</p>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" @click="showModal = false">Close</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>

</div>
</template>
<script>

export default {
  name: 'MyCalculator',
  props: {
    msg: String
  },
  data() {
    return {
      showErrorNumber1: false,
      showErrorNumber2: false,
      showErrorExternalUrl: false,
      Number1Input: "",
      Number2Input: "",
      Result: "",
      showModal: false,
      ExternalUrl: ""
    }
  },
  beforeMount() {
      console.log('Requested url to remote service');
      fetch("/extra/url.json")
        .then(response => response.json())
        .then(data => {
          this.ExternalUrl = data.url;
          console.log("Externl url = " + this.ExternalUrl);
        })
        .catch(err =>{
          this.ExternalUrl = "";
          console.log("Error in fetch url: " + err);
        })
  },
  methods: {
    SumLocally() {
      if (this.CheckErrorInInputNumer()) return;

      const tot = this.Number1Input + this.Number2Input;
      this.Result = tot;
      this.showModal = true;
    },
    async SumRemotely() {
      this.showErrorExternalUrl = this.ExternalUrl == "";
      if (this.ExternalUrl != "") {
        if (this.CheckErrorInInputNumer()) return;

        console.log("external request to " + this.ExternalUrl);
        const url = `${this.ExternalUrl}/api/calc/add?x=${this.Number1Input}&y=${this.Number2Input}`;
        
        try {
          const response = await fetch(url);
          const value = await response.json();
          this.Result = value.results.result;
          this.showModal = true;
        }
        catch (err) {
          alert("Error in fetch url: " + err);
        }
      }
      else {
        setTimeout(() => this.showErrorExternalUrl = false, 3000)
      }
    },
    CheckErrorInInputNumer() {
      this.showErrorNumber1 = !Number.isInteger(this.Number1Input);
      this.showErrorNumber2 = !Number.isInteger(this.Number2Input);
      return this.showErrorNumber1 && this.showErrorNumber2;
    }
  }
}
</script>
<style scoped>
  .form-vertical-space {margin-top: 2em;}
  .text-center {
    text-align: center;
  }

.modal-mask {
  position: fixed;
  z-index: 9998;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, .5);
  display: table;
  transition: opacity .3s ease;
}

.modal-wrapper {
  display: table-cell;
  vertical-align: middle;
}
</style>