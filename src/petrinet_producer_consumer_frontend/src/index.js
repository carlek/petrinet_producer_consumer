import { petrinet_producer_consumer_backend } from "../../declarations/petrinet_producer_consumer_backend";

document.querySelector("form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const button = e.target.querySelector("button");
  const countSection = document.getElementById("count");
  const producer_num_element = document.getElementById("producer_num");
  const producer_num = parseInt(producer_num_element.value, 10); 

  button.setAttribute("disabled", true);

  countSection.innerHTML = `<p># Iterations to Exhaust All Tokens ??? </p>`;

  // Interact with actor, calling the driver method
  const count = await petrinet_producer_consumer_backend.driver(producer_num);

  button.removeAttribute("disabled");

  // document.getElementById("count").innerText = count;
  countSection.innerHTML = `<p><p># Iterations to Exhaust All Tokens = ${count}</p>`;

  return false;
});
