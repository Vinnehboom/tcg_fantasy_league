import {Controller} from "@hotwired/stimulus"

class RemovalsController extends Controller {

  connect() {
    const visible = isScrolledIntoView(this.element);
    if(!visible) {
      this.element.classList.add("position-fixed", "top-0")
    }
  }

  remove() {
    this.element.remove()
  }
}

function isScrolledIntoView(elem)
{
  let docViewTop = $(window).scrollTop();
  let docViewBottom = docViewTop + $(window).height();

  let elemTop = $(elem).offset().top;
  let elemBottom = elemTop + $(elem).height();

  return ((elemBottom <= docViewBottom) && (elemTop >= docViewTop));
}
export default RemovalsController